/* eslint-disable no-console */
/* eslint-disable no-restricted-syntax */
/* eslint-disable no-await-in-loop */
import request from './request';
import { PageAssessmentGrades } from './article_finder_language_mappings';
import { stringify } from 'query-string';
import { chunk } from 'lodash-es';

// this function takes in a wiki url and the revisions of that particular wiki
// it then finds the page assessments of all of the articles, merges them together
// and returns an object in the form of {revision_id: {rating, pretty_rating, rating_num}, ...}
const fetchClassFromRevisionsOfWiki = async (wiki_url, revisionsOfWiki) => {
  // remove duplicates -> each article occurs only once after this
  const prefix = `https://${wiki_url}`;
  const API_URL = `${prefix}/w/api.php`;
  // eslint-disable-next-line no-console
  console.log(`Fetching page assessments from ${wiki_url}`);

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
