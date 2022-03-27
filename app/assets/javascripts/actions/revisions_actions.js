import {
  RECEIVE_REVISIONS,
  REVISIONS_LOADING,
  RECEIVE_COURSE_SCOPED_REVISIONS,
  COURSE_SCOPED_REVISIONS_LOADING,
  SORT_REVISIONS,
  API_FAIL
} from '../constants';
import { fetchWikidataLabelsForRevisions } from './wikidata_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import API from '../utils/api';
import moment from 'moment';
import { stringify } from 'query-string';
import { PageAssessmentGrades, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings';

const fetchClassFromRevisions = async (wiki, API_URL, revisions) => {
  // remove duplicates -> each article occurs only once after this
  const uniqueArticles = [...new Set(revisions.map(revision => revision.title))];
  const titles = uniqueArticles.join('|');

  const params = {
    action: 'query',
    format: 'json',
    titles,
    prop: 'pageassessments',
    pasubprojects: false,
    palimit: 50
  };
  const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
  const ratings = (await response.json()).query.pages;


  /* eslint-disable no-restricted-syntax */
  for (const revision of revisions) {
    // if pageassessments exists
    if (ratings[revision.pageid].pageassessments) {
      // pick the first key of the object pageassessments
      let rating;
      for (const value of Object.values(ratings[revision.pageid].pageassessments)) {
        if (value.class) {
          rating = value.class;
          break;
        }
      }
      if (rating) {
        const mapping = PageAssessmentGrades[wiki.project][wiki.language][rating];
        if (mapping) {
          revision.rating_num = mapping.score;
          revision.pretty_rating = mapping.pretty;
          revision.rating = mapping.class;
        }
      }
    }
  }
  /* eslint-enable no-restricted-syntax */
};
const fetchRevisionsFromWiki = async (wiki, usernames, start_time, end_time) => {
  const params = {
    action: 'query',
    format: 'json',
    list: 'usercontribs',
    ucuser: usernames,
    ucprop: 'ids|title|sizediff|timestamp',
    uclimit: 50,
    ucend: start_time,
    ucstart: end_time,
    ucdir: 'older',
  };

  let prefix;
  if (wiki.language) {
    prefix = `https://${wiki.language}.${wiki.project}.org`;
  } else {
    prefix = `https://${wiki.project}.org`;
  }

  const API_URL = `${prefix}/w/api.php`;

  const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
  const json = await response.json();
  const revisions = json.query.usercontribs;
  /* eslint-disable no-restricted-syntax */

  for (const revision of revisions) {
    revision.wiki = wiki;
    const diff_params = {
      title: revision.title,
      diff: 'prev',
      oldid: revision.parentid
    };

    // url for the diff
    revision.url = `${prefix}/w/index.php?${stringify(diff_params)}`;

    // main article url - we use stringify to ensure that its encoded properly
    revision.article_url = `${prefix}/w/index.php?${stringify({ title: revision.title })}`;

    // to maintain the old structure of the revision object
    revision.characters = revision.sizediff;
    revision.mw_rev_id = revision.revid;
    revision.id = revision.revid;
    revision.revisor = revision.user;
    revision.date = revision.timestamp;
    revision.mw_page_id = revision.pageid;
  }
  /* eslint-enable no-restricted-syntax */


  if (PageAssessmentSupportedWiki?.[wiki.project]?.[wiki.language]) {
    // the wiki supports page assessments
    await fetchClassFromRevisions(wiki, API_URL, revisions);
  }

  return revisions;
};

const fetchRevisionsFromUsers = async (course, users) => {
  const usernames = users.map(user => user.username).join('|');

  // Converting to ISO 8601 format
  // the Media Wiki API doesn't accept fractional seconds. This gets rid of that
  const start_time = moment.utc(course.timeline_start).format();
  const end_time = moment.utc(course.timeline_end).format();

  const revisions = [];

  /* eslint-disable no-restricted-syntax */
  for (const wiki of course.wikis) {
    /* eslint-disable no-await-in-loop */
    const items = await fetchRevisionsFromWiki(wiki, usernames, start_time, end_time);
    revisions.push(...items);
    /* eslint-enable no-await-in-loop */
  }
  /* eslint-enable no-restricted-syntax */

  revisions.sort((revision1, revision2) => {
    const date1 = new Date(revision1.date);
    const date2 = new Date(revision2.date);
    return date2.getTime() - date1.getTime();
  });
  return revisions;
};

const fetchRevisionsPromise = async (course, limit, isCourseScoped, users) => {
  if (!isCourseScoped) {
    course.revisions = await fetchRevisionsFromUsers(course, users);
    return { course };
  }
  const response = await request(`/courses/${course.slug}/revisions.json?limit=${limit}&course_scoped=${isCourseScoped}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const fetchRevisions = (course, limit, isCourseScoped = false) => async (dispatch, getState) => {
  const courseId = course.slug;
  let actionType;
  if (isCourseScoped) {
    actionType = RECEIVE_COURSE_SCOPED_REVISIONS;
    dispatch({ type: COURSE_SCOPED_REVISIONS_LOADING });
  } else {
    actionType = RECEIVE_REVISIONS;
    dispatch({ type: REVISIONS_LOADING });
  }
  const state = getState();
  let users;
  if (state.users.users.length) {
    // the users list has already been fetched
    users = state.users.users;
  } else {
    try {
      const response = await API.fetch(courseId, 'users');
      users = response.course.users;
    } catch (e) {
      dispatch({ type: API_FAIL, data: e });
      return;
    }
  }
  return (
    fetchRevisionsPromise(course, limit, isCourseScoped, users)
      .then((resp) => {
        dispatch({
          type: actionType,
          data: resp,
          limit: limit
        });
        // Now that we received the revisions data, query wikidata.org for the labels
        // of any Wikidata entries that are among the revisions.
        fetchWikidataLabelsForRevisions(resp.course.revisions, dispatch);
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortRevisions = key => ({ type: SORT_REVISIONS, key: key });
