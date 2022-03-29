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
import { ORESSupportedWiki, PageAssessmentGrades, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings';
import { url } from '../utils/wiki_utils';
import { chunk, flatten } from 'lodash-es';
import { queryUrl } from '../utils/article_finder_utils';

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

  const uniqueArticles = [...new Set(revisionsOfWiki.filter(revision => revision.ns === 0).map(revision => revision.title))];
  const allRatings = [];
  const chunks = chunk(uniqueArticles, 50);
  for (const uniqueArticlesChunk of chunks) {
    const params = {
      action: 'query',
      format: 'json',
      titles: uniqueArticlesChunk.join('|'),
      prop: 'pageassessments',
      pasubprojects: false,
      palimit: 500
    };
    const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
    const pages = (await response.json())?.query?.pages;
    if (pages) { allRatings.push(pages); }
  }
  if (!allRatings) {
    // no ratings found
    return;
  }
  // merge list of objects of ratings into a single object
  const ratings = Object.assign({}, ...allRatings);
  const assessments = {};
  /* eslint-disable no-restricted-syntax */
  for (const revision of revisionsOfWiki) {
    const assessment = {};
    // if pageassessments exists
    if (ratings?.[revision.pageid]?.pageassessments) {
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
};

const getReferences = (item) => {
  const features = item?.articlequality?.features;
  return features?.['feature.wikitext.revision.ref_tags']
        || features?.['feature.len(<datasource.wikidatawiki.revision.references>)']
        || features?.['feature.enwiki.revision.shortened_footnote_templates']
        || 0;
};

const fetchReferencesAdded = async (prevReferences, wikiMap) => {
  // eslint-disable-next-line no-restricted-syntax
  const referencesPromises = [];
  // eslint-disable-next-line no-restricted-syntax
  for (const [wiki_url, revisionsOfWiki] of wikiMap) {
    referencesPromises.push(fetchReferencesAddedFromWiki(wiki_url, revisionsOfWiki));
  }
  const resolvedValues = await Promise.all(referencesPromises);

  // merge array of objects into one object
  const allReferences = Object.assign({}, ...resolvedValues);

  // return after merging previous References and current
  return Object.assign({}, ...[allReferences, prevReferences]);
};

const fetchReferencesAddedFromWiki = async (wiki_url, revisions) => {
  const list = wiki_url.split('.');
  let wiki;
  if (list.length === 3) {
    wiki = { language: list[0], project: list[1] };
  } else {
    wiki = { project: list[0] };
  }
  if (
    !ORESSupportedWiki.projects.includes(wiki.project)
  && !ORESSupportedWiki.languages.includes(wiki.language)
  ) {
    // wiki does not support ORES
    return;
  }
  let suffix;
  if (wiki.project === 'wikidata') {
    suffix = 'wikidatawiki';
  } else {
    suffix = `${wiki.language}wiki`;
  }
  const API_URL = `http://ores.wikimedia.org/v3/scores/${suffix}`;
  const revids = revisions.filter(revision => revision.ns === 0).map(revision => `${revision.parentid}|${revision.revid}`);
  const chunks = chunk(revids, 25);
  // eslint-disable-next-line no-restricted-syntax

  const promises = [];
  // eslint-disable-next-line no-restricted-syntax
  for (const revid_chunk of chunks) {
    const params = {
      revids: revid_chunk.join('|'),
      features: true,
      models: 'articlequality'
    };

    promises.push(queryUrl(`${API_URL}`, params));
  }
  // get the scores and remove all undefined values
  // this is an array of objects
  const values = (await Promise.all(promises)).map(data => data[suffix].scores).filter(item => item);

  // merge the array of objects into one object
  const combinedObject = Object.assign({}, ...values);

  const referencesAdded = {};
  // eslint-disable-next-line no-restricted-syntax
  for (const revision of revisions) {
    const references = getReferences(combinedObject?.[revision.revid]);
    if (references) {
      referencesAdded[revision.revid] = references - getReferences(combinedObject?.[revision.parentid]);
    }
  }
  return referencesAdded;
};

const fetchRevisionsAndReferences = async (prevReferences, prevAssessments, revisions, dispatch) => {
  const wikiMap = new Map();
  // eslint-disable-next-line no-restricted-syntax
  for (const revision of revisions) {
    if (
      PageAssessmentSupportedWiki?.[revision.wiki.project]?.includes(revision.wiki.language)
      || ORESSupportedWiki.projects.includes(revision.wiki.project)
      || ORESSupportedWiki.languages.includes(revision.wiki.language)
    ) {
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
  }
  fetchClassFromRevisions(prevAssessments, wikiMap)
  .then(
    assessments => dispatch({
      type: 'RECEIVE_ASSESSMENTS',
      data: { assessments }
    })
  );

  fetchReferencesAdded(prevReferences, wikiMap).then((referencesAdded) => {
    dispatch({
      type: 'RECEIVE_REFERENCES',
      data: { referencesAdded }
    });
  });
};

const fetchClassFromRevisions = async (prevAssessments, wikiMap) => {
  // eslint-disable-next-line no-restricted-syntax
  const assessmentsPromises = [];
  // eslint-disable-next-line no-restricted-syntax
  for (const [wiki_url, revisionsOfWiki] of wikiMap) {
    assessmentsPromises.push(fetchClassFromRevisionsOfWiki(wiki_url, revisionsOfWiki));
  }
  const resolvedValues = await Promise.all(assessmentsPromises);

  // merge all the assessments
  const allAssessments = Object.assign({}, ...resolvedValues);

  // merge the previous and current assessments
  return Object.assign({}, ...[allAssessments, prevAssessments]);
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
  return { revisions, last_date };
};

const fetchRevisionsPromise = async (course, limit, isCourseScoped, users, last_date, prevAssessments, prevReferences, dispatch) => {
  if (!isCourseScoped) {
    const { revisions, last_date: new_last_date } = await fetchRevisionsFromUsers(course, users, 7, last_date);
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
    // we don't await this. When the assessments/references get laoded, the action is dispatched
    fetchRevisionsAndReferences(prevReferences, prevAssessments, revisions, dispatch);
    return { course, last_date: new_last_date };
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
    fetchRevisionsPromise(course, limit, isCourseScoped, users, state.revisions.last_date, state.revisions.assessments, state.revisions.referencesAdded, dispatch)
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
