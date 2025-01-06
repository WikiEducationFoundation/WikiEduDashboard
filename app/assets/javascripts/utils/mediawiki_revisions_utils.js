/* eslint-disable no-restricted-syntax */
/* eslint-disable no-await-in-loop */

import { flatten, chunk } from 'lodash-es';
import { stringify } from 'query-string';
import request from './request';
import { toWikiDomain } from './wiki_utils';
import { toDate } from './date_utils';
import { subDays, formatISO, subYears, isBefore } from 'date-fns';

// the MediaWiki API sends back revisions in pages
// except the last page, each page has a continue token
// that continue token must be included in the request to fetch the next page
// this helper function exists to fetch and merge all those pages into one
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
    if (allData.length >= 1000) {
      // we have enough revisions - don't need to burden the API
      return allData;
    }
    if (json.continue) {
      continueToken = json.continue;
    } else {
      hasMore = false;
    }
  }
  return allData;
};

// filter is a function which is used to filter the fetched articles
// currently its used to filter tracked articles
export const fetchRevisionsFromUsers = async (course, users, days, last_date, filter) => {
  const usernames = users.map(user => user.username);

  let revisions = [];
  const wikiPromises = [];

  // request until we find 50 revisions or the date is outside the course duration
  // the last we fetch is up until 5 years ago
  let keepRunning = true;
  while (revisions.length < 50 && keepRunning) {
    for (const wiki of course.wikis) {
      wikiPromises.push(fetchRevisionsFromWiki(days, wiki, usernames, course.start, last_date));
    }
    const resolvedValues = await Promise.all(wikiPromises);
    for (const value of resolvedValues) {
      const { revisions: items, exitNext } = value;
      keepRunning = !exitNext;
      if (filter) {
        revisions.push(...(items.filter(filter)));
      } else {
        // if filter is not passed, simply add all the revisions
        revisions.push(...items);
      }
    }
    last_date = formatISO(subDays(toDate(last_date), days));
    if (revisions.length < 50) {
      // go back at most 2 years
      days = Math.min(365 * 2, 3 * days);
    }
  }
  // remove duplicates
  // they occur because dates overlap and sometimes the same revision is included twice
  revisions = [...new Map(revisions.map(v => [v.id, v])).values()];

  return { revisions, last_date };
};

// fetches revisions from a particular wiki
// days is the time period to fetch for. For example, if it is 7 days, and the last_date
// is today's date, it will look for revisions from the past week
const fetchAllRevisions = async (API_URL, days, usernames, wiki, course_start, last_date) => {
  let ucend;
  let exitNext = false;
  if (isBefore(subDays(toDate(last_date), days), toDate(course_start))) {
    ucend = formatISO(toDate(course_start));
    exitNext = true;
  } else if (isBefore(subDays(toDate(last_date), days), subYears(new Date(), 5))) {
    ucend = formatISO(subYears(new Date(), 5));
    exitNext = true;
  } else {
    ucend = formatISO(subDays(toDate(last_date), days));
  }

  // since a max of 50 users are allowed in one query
  const usernamesChunks = chunk(usernames, 50);
  const usernamePromises = [];

  for (const usernameChunk of usernamesChunks) {
    const params = {
      action: 'query',
      format: 'json',
      list: 'usercontribs',
      ucuser: usernameChunk.join('|'),
      ucprop: 'ids|title|sizediff|timestamp',
      uclimit: 50,
      ucend,
      ucstart: formatISO(toDate(last_date)),
      ucdir: 'older',
    };
    usernamePromises.push(fetchAll(API_URL, params, 'uccontinue'));
  }
  const values = await Promise.all(usernamePromises);
  const revisions = flatten(values);
  return { revisions, exitNext };
};

// wrapper function around fetchAllRevisions. This gets all the revisions returned by that function
// adds some properties we require on the front end, like url, article_url, etc
const fetchRevisionsFromWiki = async (days, wiki, usernames, course_start, last_date) => {
  const prefix = `https://${toWikiDomain(wiki)}`;
  const API_URL = `${prefix}/w/api.php`;
  const { revisions, exitNext } = await fetchAllRevisions(API_URL, days, usernames, wiki, course_start, last_date);
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
    revision.article_url = `${prefix}/wiki/${encodeURIComponent(revision.title)}`;

    // to maintain the old structure of the revision object
    revision.characters = revision.sizediff;
    revision.mw_rev_id = revision.revid;
    revision.id = revision.revid;
    revision.revisor = revision.user;
    revision.date = revision.timestamp;
    revision.mw_page_id = revision.pageid;
  }
  return { revisions, wiki, exitNext };
};

const parseRevisionResponse = (json) => {
  const page = Object.values(json.query.pages)[0];
  if (page.revisions) {
    return { pageid: page.pageid, ...page.revisions[0] };
  }
};

const fetchEarliestRef = async (API_URL, articleTitle, username, startDate, endDate) => {
  const params = {
    action: 'query',
    format: 'json',
    prop: 'revisions',
    titles: articleTitle,
    rvprop: 'timestamp|user|ids',
    rvuser: username,
    rvdir: 'newer',
    rvlimit: 1,
    rvstart: formatISO(toDate(startDate)),
    rvend: formatISO(toDate(endDate)),
  };

  const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
  const json = await response.json();
  return parseRevisionResponse(json);
};

const fetchLatestRef = async (API_URL, articleTitle, username, startDate, endDate) => {
  const params = {
    action: 'query',
    format: 'json',
    prop: 'revisions',
    titles: articleTitle,
    rvprop: 'timestamp|user|ids',
    rvuser: username,
    rvdir: 'older',
    rvlimit: 1,
    rvstart: formatISO(toDate(endDate)),
    rvend: formatISO(toDate(startDate))
  };

  const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
  const json = await response.json();
  return parseRevisionResponse(json);
};

const earliestRev = (revs) => {
  let earliest;
  for (const rev of revs) {
    if (rev) {
      if (!earliest) { earliest = rev; }
      if (toDate(rev.timestamp) < toDate(earliest.timestamp)) { earliest = rev; }
    }
  }
  return earliest;
};

const latestRev = (revs) => {
  let latest;
  for (const rev of revs) {
    if (rev) {
      if (!latest) { latest = rev; }
      if (toDate(rev.timestamp) > toDate(latest.timestamp)) { latest = rev; }
    }
  }
  return latest;
};

export const getRevisionRange = async (API_URL, articleTitle, usernames, startDate, endDate) => {
  let firstRevs = [];
  let lastRevs = [];
  for (const username of usernames) {
    firstRevs.push(fetchEarliestRef(API_URL, articleTitle, username, startDate, endDate));
    lastRevs.push(fetchLatestRef(API_URL, articleTitle, username, startDate, endDate));
  }
  firstRevs = await Promise.all(firstRevs);
  lastRevs = await Promise.all(lastRevs);
  return { first_revision: earliestRev(firstRevs), last_revision: latestRev(lastRevs) };
};

export const fetchLatestRevisionsForUser = async (username, wiki) => {
  const prefix = `https://${toWikiDomain(wiki)}`;
  const API_URL = `${prefix}/w/api.php`;

  const params = {
    action: 'query',
    format: 'json',
    list: 'usercontribs',
    ucuser: username,
    ucprop: 'ids|title|timestamp|sizediff'
  };

  const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
  const json = await response.json();
  return json.query.usercontribs;
};
