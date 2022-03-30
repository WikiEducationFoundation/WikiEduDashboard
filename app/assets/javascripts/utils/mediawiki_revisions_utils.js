/* eslint-disable no-restricted-syntax */
/* eslint-disable no-restricted-syntax */
/* eslint-disable no-console */
/* eslint-disable no-await-in-loop */

import { fetchAll } from './revision_utils';
import { flatten, chunk } from 'lodash-es';
import { stringify } from 'query-string';
import { url } from './wiki_utils';
import moment from 'moment';

export const fetchRevisionsFromUsers = async (course, users, days, last_date) => {
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

// fetches revisions from a particular wiki
// days is the time period to fetch for. For example, if it is 7 days, and the last_date
// is today's date, it will look for revisions from the past week
const fetchAllRevisions = async (API_URL, days, usernames, wiki, course_start, last_date) => {
  let ucend;
  if (moment(last_date).subtract(days, 'days').isBefore(course_start)) {
    ucend = moment(course_start).format();
  } else {
    ucend = moment(last_date).subtract(days, 'days').format();
  }

  console.log(`Fetching revisions between ${moment(last_date).format()} and ${ucend} -> ${days} days from ${API_URL}`);
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

// wrapper function around fetchAllRevisions. This gets all the revisions returned by that function
// adds some properties we require on the front end, like url, article_url, etc
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
    revision.article_url = `${prefix}/wiki/${encodeURIComponent(revision.title)}`;

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

