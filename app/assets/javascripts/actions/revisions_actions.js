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
import moment from 'moment';
import { stringify } from 'query-string';
import { PageAssessmentGrades, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings';
import { url } from '../utils/wiki_utils';

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
  const ratings = (await response.json())?.query?.pages;

  if (!ratings) {
    // no ratings found
    return;
  }

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
const fetchRevisionsFromWiki = async (wiki, usernames, start_time, prevContinueToken) => {
  const params = {
    action: 'query',
    format: 'json',
    list: 'usercontribs',
    ucuser: usernames,
    ucprop: 'ids|title|sizediff|timestamp',
    uclimit: 50,
    ucend: start_time,
    ucdir: 'older',
  };

  if (prevContinueToken) {
    // if token exists, add it.
    params.uccontinue = prevContinueToken.uccontinue;
    params.continue = prevContinueToken.continue;
  }

  const prefix = `https://${url(wiki)}`;

  const API_URL = `${prefix}/w/api.php`;

  let response;
  try {
    response = await request(`${API_URL}?${stringify(params)}&origin=*`);
    if (!response.ok) {
      throw response;
    }
  } catch (e) {
    return { revisions: [], continueToken: undefined, wiki };
  }
  const json = await response.json();
  const revisions = json.query.usercontribs;
  const continueToken = json.continue;
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

  if (PageAssessmentSupportedWiki?.[wiki.project]?.includes(wiki.language)) {
    // the wiki supports page assessments
    await fetchClassFromRevisions(wiki, API_URL, revisions);
  }

  return { revisions, continueToken, wiki };
};

const fetchRevisionsFromUsers = async (course, users, continueTokens = {}) => {
  const usernames = users.map(user => user.username).join('|');

  // Converting to ISO 8601 format
  // the Media Wiki API doesn't accept fractional seconds. This gets rid of that
  const start_time = moment.utc(course.timeline_start).format();

  const revisions = [];
  const wikiPromises = [];
  /* eslint-disable no-restricted-syntax */
  for (const wiki of course.wikis) {
    if (continueTokens[url(wiki)] === 'no-continue') {
      // eslint-disable-next-line no-continue
      continue;
    }
    wikiPromises.push(fetchRevisionsFromWiki(wiki, usernames, start_time, continueTokens?.[url(wiki)]));
  }
  const resolvedValues = await Promise.all(wikiPromises);
  for (const value of resolvedValues) {
    const { revisions: items, continueToken, wiki } = value;
    revisions.push(...items);
    if (continueToken) {
      continueTokens[url(wiki)] = (continueToken);
    } else {
      continueTokens[url(wiki)] = 'no-continue';
    }
  }

  /* eslint-enable no-restricted-syntax */
  return { revisions, continueTokens };
};

const fetchRevisionsPromise = async (course, limit, isCourseScoped, users, contTokens) => {
  if (!isCourseScoped) {
    const { revisions, continueTokens } = await fetchRevisionsFromUsers(course, users, contTokens);
    if (course.revisions) {
      course.revisions = course.revisions.concat(revisions);
    } else {
      course.revisions = revisions;
    }
    course.revisions = course.revisions.sort((revision1, revision2) => {
      const date1 = new Date(revision1.date);
      const date2 = new Date(revision2.date);
      return date2.getTime() - date1.getTime();
    });
    return { course, continueTokens };
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
  let actionType;
  if (isCourseScoped) {
    actionType = RECEIVE_COURSE_SCOPED_REVISIONS;
    dispatch({ type: COURSE_SCOPED_REVISIONS_LOADING });
  } else {
    actionType = RECEIVE_REVISIONS;
    dispatch({ type: REVISIONS_LOADING });
  }
  const state = getState();
  const users = state.users.users;
  if (users.length === 0) {
    course.revisions = [];
    dispatch({
      type: actionType,
      data: { course, continueTokens: {} },
      limit: limit
    });
    return;
  }
  return (
    fetchRevisionsPromise(course, limit, isCourseScoped, users, state.revisions.continueTokens)
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
