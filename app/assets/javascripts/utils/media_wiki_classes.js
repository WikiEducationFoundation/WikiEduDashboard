/* eslint-disable no-restricted-syntax */
/* eslint-disable no-await-in-loop */
import request from './request';
import { stringify } from 'query-string';
import { chunk } from 'lodash-es';
import { getAssessments } from './revision_utils';
// this function takes in a wiki url and the revisions of that particular wiki
// it then finds the page assessments of all of the articles, merges them together
// and returns an object in the form of {revision_id: {rating, pretty_rating, rating_num}, ...}
const fetchClassFromRevisionsOfWiki = async (wiki_url, revisionsOfWiki) => {
  // remove duplicates -> each article occurs only once after this
  const prefix = `https://${wiki_url}`;
  const API_URL = `${prefix}/w/api.php`;

  const uniqueArticles = [...new Set(revisionsOfWiki.filter(revision => revision.ns === 0).map(revision => revision.title))];
  const chunks = chunk(uniqueArticles, 50);
  const allPromises = [];

  // takes in a list of articles, and requests for their class information
  // eslint-disable-next-line no-shadow
  const getClassesForArticles = async (API_URL, articles) => {
    const params = {
      action: 'query',
      format: 'json',
      titles: articles.join('|'),
      prop: 'pageassessments',
      pasubprojects: false,
      palimit: 500
    };
    const response = await request(`${API_URL}?${stringify(params)}&origin=*`);
    const pages = (await response.json())?.query?.pages;
    if (pages) {
      return pages;
    }
  };

  for (const uniqueArticlesChunk of chunks) {
    allPromises.push(getClassesForArticles(API_URL, uniqueArticlesChunk));
  }
  const resolvedValues = await Promise.all(allPromises);
  if (!resolvedValues.length) {
    // no ratings found
    return {};
  }
  return getAssessments(resolvedValues, revisionsOfWiki);
};

// this functions takes in the previous assessments information, and a mapping between the wiki and
// a list of its revisions. It then individually finds out the classes of all wikis, and then merges them together
export const fetchClassFromRevisions = async (wikiMap) => {
  const assessmentsPromises = [];

  for (const [wiki_url, revisionsOfWiki] of wikiMap) {
    assessmentsPromises.push(fetchClassFromRevisionsOfWiki(wiki_url, revisionsOfWiki));
  }
  const resolvedValues = await Promise.all(assessmentsPromises);

  // merge all the assessments and return
  return Object.assign({}, ...resolvedValues);
};


