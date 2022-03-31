/* eslint-disable no-await-in-loop */
/* eslint-disable no-restricted-syntax */
import request from './request';
import { stringify } from 'query-string';
import { ORESSupportedWiki, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings';
import { url } from './wiki_utils';

// the MediaWiki API sends back revisions in pages
// except the last page, each page has a continue token
// that continue token must be included in the request to fetch the next page
// this helper function exists to fetch and merge all those pages into one
export const fetchAll = async (API_URL, params, continue_str) => {
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

// uses the ORES API to get the number of references in a particular revision
export const getReferencesCount = (item) => {
  const features = item?.articlequality?.features;
  return features?.['feature.wikitext.revision.ref_tags']
        || features?.['feature.len(<datasource.wikidatawiki.revision.references>)']
        || features?.['feature.enwiki.revision.shortened_footnote_templates']
        || 0;
};

// this helper function returns a mapping between the different wikis and the various
// revisions which belong to it
// for example, {"en.wikipedia.org": [rev1, rev2], "fr.wikipedia.org": [rev4, rev3]}
export const getWikiMap = (revisions) => {
  const wikiMap = new Map();
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
  return wikiMap;
};

export const sortRevisionsByDate = (revisions) => {
  return revisions.sort((revision1, revision2) => {
    const date1 = new Date(revision1.date);
    const date2 = new Date(revision2.date);
    return date2.getTime() - date1.getTime();
  });
};
