/* eslint-disable no-restricted-syntax */
import { ORESSupportedWiki } from './article_finder_language_mappings';
import { queryUrl } from './article_finder_utils';
import { chunk } from 'lodash-es';
import { getReferencesCount } from './revision_utils';

import promiseLimit from 'promise-limit';

const limit = promiseLimit(10);

// given a particular wiki, find all the references added for each revision in it
const fetchReferencesAddedFromWiki = async (wiki_url, revisions) => {
  // eslint-disable-next-line no-console
  console.log(`Fetching references information from ${wiki_url}`);

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
  const revids = revisions.filter(revision => revision.ns === 0).map(revision => `${revision.parentid}|${revision.revid}`);
  const chunks = chunk(revids, 25);

  const values = (await Promise.all(chunks.map((revid_chunk) => {
    // at max 10 requests at a time
    return limit(() => {
      const params = {
        revids: revid_chunk.join('|'),
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
    const references = getReferencesCount(combinedObject?.[revision.revid]);
    if (references) {
      referencesAdded[revision.revid] = references - getReferencesCount(combinedObject?.[revision.parentid]);
    } else {
      referencesAdded[revision.revid] = 0;
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
