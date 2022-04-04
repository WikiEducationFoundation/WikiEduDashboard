/* eslint-disable no-await-in-loop */
/* eslint-disable no-restricted-syntax */
import { ORESSupportedWiki, PageAssessmentSupportedWiki, PageAssessmentGrades } from '../utils/article_finder_language_mappings';
import { url } from './wiki_utils';

// this helper function takes in a list of objects of the ratings as returned by the ORES API
// it first merges all the objects into one big one and extracts the assessment information.
// it returns an assessment object, the keys of which are revision ids and the value is an object of the form
// {rating_num, rating, pretty_rating}
export const getAssessments = (allRatings, revisions) => {
  const ratings = Object.assign({}, ...allRatings);
  const assessments = {};
  for (const revision of revisions) {
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

// extracts the number of references in a particular revision
export const getReferencesCount = (item, wikidata = false) => {
  const features = wikidata ? item?.itemquality?.features : item?.articlequality?.features;
  return features?.['feature.wikitext.revision.ref_tags']
        || features?.['feature.len(<datasource.wikidatawiki.revision.references>)']
        || features?.['feature.enwiki.revision.shortened_footnote_templates'];
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
