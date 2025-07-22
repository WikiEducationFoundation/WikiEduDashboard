/* eslint-disable no-restricted-syntax */
import { queryUrl } from './article_finder_utils';
import { chunk } from 'lodash-es';
import { getReferencesAdded, getWikiObjectFromURL, isSupportedORESWiki } from './revision_utils';

import promiseLimit from 'promise-limit';

const limit = promiseLimit(5);

// given a particular wiki, find all the references added for each revision in it
const fetchReferencesAddedFromWiki = async (wiki_url, revisions) => {
  const wiki = getWikiObjectFromURL(wiki_url);
  if (!isSupportedORESWiki(wiki)) {
    // wiki is not supported
    return;
  }
  let models;
  let suffix;
  if (wiki.project === 'wikidata') {
    suffix = 'wikidatawiki';
    models = 'itemquality';
  } else {
    suffix = `${wiki.language}wiki`;
    models = 'articlequality';
  }
  const API_URL = `https://ores.wikimedia.org/v3/scores/${suffix}`;
  // first filter the revisions in namespace 0
  // then map them to a string of the format "{parent_rev_id}|{rev_id}"
  const revids = revisions.filter(revision => revision.ns === 0).map(revision => `${revision.parentid}|${revision.revid}`);
  // this means that each item of this array has 2 revisions.
  // since the max revisions allowed by the ORES API for a single request is 50,
  // we must divide the array into sub arrays, each of max size 25
  const chunks = chunk(revids, 25);

  const values = (await Promise.all(chunks.map((revid_chunk) => {
    // at max 10 requests at a time
    return limit(() => {
      const params = {
        revids: revid_chunk.join('|'), // join all the strings of the array with "|".
        features: true,
        models
      };
      return queryUrl(`${API_URL}`, params).catch(() => undefined); // resolve to undefined if fails
    });
  }))).filter(item => item).map(data => data?.[suffix]?.scores);

  // merge the array of objects into one object
  const combinedObject = Object.assign({}, ...values);

  const referencesAdded = {};

  for (const revision of revisions) {
    const references = getReferencesAdded(combinedObject, revision);
    if (references !== undefined) {
      referencesAdded[revision.revid] = references;
    }
  }
  return referencesAdded;
};

export const fetchReferencesAdded = async (wikiMap) => {
  const referencesPromises = [];
  for (const [wiki_url, revisionsOfWiki] of wikiMap) {
    referencesPromises.push(fetchReferencesAddedFromWiki(wiki_url, revisionsOfWiki));
  }
  const resolvedValues = await Promise.all(referencesPromises);

  // merge array of objects into one object and return
  return Object.assign({}, ...resolvedValues);
};
