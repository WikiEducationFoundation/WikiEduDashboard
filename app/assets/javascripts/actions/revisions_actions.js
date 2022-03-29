/* eslint-disable no-await-in-loop */

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
import { chunk, flatten } from 'lodash-es';

const fetchAll = async (API_URL, params, continue_str) => {
  const allData = [];
  let continueToken;
  let hasMore = true;
  while (hasMore) {
    let response;
    if (continueToken) {
      params[continue_str] = continueToken[continue_str];
      params.continue = continueToken.continue;
    }
    try {
      response = await request(`${API_URL}?${stringify(params)}&origin=*`);
      if (!response.ok) {
        throw response;
      }
    } catch (e) {
      return allData;
    }
    const json = await response.json();
    allData.push(...json.query.usercontribs);
    if (json.continue) {
      continueToken = json.continue;
    } else {
      hasMore = false;
    }
  }
  return allData;
};
const fetchAllRevisions = async (API_URL, days, usernames, wiki, course_start, last_date) => {
  let ucend;
  if (moment(last_date).subtract(days, 'days').isBefore(course_start)) {
    ucend = moment(course_start).format();
  } else {
    ucend = moment(last_date).subtract(days, 'days').format();
  }
  // since a max of 50 users are allowed in one query
  const usernamesChunks = chunk(usernames, 50);
  const usernamePromises = [];
  /* eslint-disable no-restricted-syntax */
  for (const usernameChunk of usernamesChunks) {
    const params = {
      action: 'query',
      format: 'json',
      list: 'usercontribs',
      ucuser: usernameChunk.join('|'),
      ucprop: 'ids|title|sizediff|timestamp',
      uclimit: 50,
      ucend,
      ucstart: moment(last_date).format(),
      ucdir: 'older',
    };
    usernamePromises.push(fetchAll(API_URL, params, 'uccontinue'));
  }
  const values = await Promise.all(usernamePromises);
  const revisions = flatten(values);
  return revisions;
};

const fetchClassFromRevisionsOfWiki = async (wiki_url, revisionsOfWiki) => {
  // remove duplicates -> each article occurs only once after this
  const prefix = `https://${wiki_url}`;
  const API_URL = `${prefix}/w/api.php`;

  const uniqueArticles = [...new Set(revisionsOfWiki.map(revision => revision.title))];
  const titles = uniqueArticles.join('|');

  const params = {
    action: 'query',
    format: 'json',
    titles,
    prop: 'pageassessments',
    pasubprojects: false,
    palimit: 200
  };
  const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
  const ratings = (await response.json())?.query?.pages;

  if (!ratings) {
    // no ratings found
    return;
  }
  const assessments = {};
  /* eslint-disable no-restricted-syntax */
  for (const revision of revisionsOfWiki) {
    const assessment = {};
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
        const mapping = PageAssessmentGrades[revision.wiki.project][revision.wiki.language][rating];
        if (mapping) {
          assessment.rating_num = mapping.score;
          assessment.pretty_rating = mapping.pretty;
          assessment.rating = mapping.class;
        }
      }
    }
    assessments[revision.revid] = assessment;
  }
  return assessments;
  /* eslint-enable no-restricted-syntax */
};

const fetchClassFromRevisions = async (prevAssessments, revisions, dispatch) => {
  const wikiMap = new Map();
  // eslint-disable-next-line no-restricted-syntax
  for (const revision of revisions) {
    if (!PageAssessmentSupportedWiki?.[revision.wiki.project]?.includes(revision.wiki.language)) {
      // eslint-disable-next-line no-continue
      continue;
    }
    if (wikiMap.has(url(revision.wiki))) {
      const value = wikiMap.get(url(revision.wiki));
      value.push(revision);
      wikiMap.set(url(revision.wiki), value);
    } else {
      const value = [];
      value.push(revision);
      wikiMap.set(url(revision.wiki), value);
    }
  }
  // eslint-disable-next-line no-restricted-syntax
  const assessmentsPromises = [];
  // eslint-disable-next-line no-restricted-syntax
  for (const [wiki_url, revisionsOfWiki] of wikiMap) {
    assessmentsPromises.push(fetchClassFromRevisionsOfWiki(wiki_url, revisionsOfWiki));
  }
  const resolvedValues = await Promise.all(assessmentsPromises);

  // merge all the assessments
  const allAssessments = Object.assign({}, ...resolvedValues);

  dispatch({
    type: 'RECEIVE_ASSESSMENTS',
    data: { assessments: Object.assign({}, ...[allAssessments, prevAssessments]) }
  });
};

const fetchRevisionsFromWiki = async (days, wiki, usernames, course_start, last_date) => {
  const prefix = `https://${url(wiki)}`;
  const API_URL = `${prefix}/w/api.php`;
  const revisions = await fetchAllRevisions(API_URL, days, usernames, wiki, course_start, last_date);
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
  return { revisions, wiki };
};

const fetchRevisionsFromUsers = async (course, users, days, last_date) => {
  const usernames = users.map(user => user.username);

  let revisions = [];
  const wikiPromises = [];
  /* eslint-disable no-restricted-syntax */

  // request until we find 50 revisions or the date is outside the course duration
  while (revisions.length < 50 && moment(last_date).isAfter(course.start)) {
    for (const wiki of course.wikis) {
      wikiPromises.push(fetchRevisionsFromWiki(days, wiki, usernames, course.start, last_date));
    }
    const resolvedValues = await Promise.all(wikiPromises);
    for (const value of resolvedValues) {
      const { revisions: items } = value;
      revisions.push(...items);
    }
    last_date = moment(last_date).subtract(days, 'days').format();
    if (revisions.length < 50) {
      days *= 3;
    }
  }
  // remove duplicates
  // they occur because dates overlap and sometimes the same revision is included twice
  revisions = [...new Map(revisions.map(v => [v.id, v])).values()];

  /* eslint-enable no-restricted-syntax */
  return { revisions, last_date, days };
};

const fetchRevisionsPromise = async (course, limit, isCourseScoped, users, days, last_date, assessments, dispatch) => {
  if (!isCourseScoped) {
    const { revisions, days: new_days, last_date: new_last_date } = await fetchRevisionsFromUsers(course, users, days, last_date);
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
    // we don't await this. When the assessments get laoded, the action is dispatched
    fetchClassFromRevisions(assessments, revisions, dispatch);
    return { course, days: new_days, last_date: new_last_date };
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
      data: { course },
      limit: limit
    });
    return;
  }
  return (
    fetchRevisionsPromise(course, limit, isCourseScoped, users, state.revisions.days, state.revisions.last_date, state.revisions.assessments, dispatch)
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
