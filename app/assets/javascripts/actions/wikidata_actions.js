import _ from 'lodash';
import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import CourseUtils from '../utils/course_utils';

const wikidataApiBase = 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json';

const fetchWikidataLabelsPromise = (qNumbers) => {
  const idsParam = _.join(qNumbers, '|');
  return new Promise((res, rej) => {
    return $.ajax({
      dataType: 'jsonp',
      url: wikidataApiBase,
      data: {
        ids: idsParam,
        props: 'labels',
        languages: `${I18n.locale}|en`
      },
      success: (data) => {
        return res(data);
      },
    })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      });
  });
};

// This takes a Wikidata page title and checks whether it looks like
// an *entity*, which could be in the Property (P), Lexeme (L), or main (Q) namespace.
// Entities have labels, while other pages are conventional wiki pages.
// Requesting the labels for an entitiy that doesn't exist will result in an API error,
// so this is used to filter out edits to (for example) WikiProject pages.
const isEntityTitle = (title) => {
  if (!title.match(/:/)) { return true; } // mainspace, aka Q item
  if (title.match(/(Property|Lexeme):/)) { return true; } // Property or Lexeme namespace, aka P or L
  return false;
};

const fetchWikidataLabels = (wikidataEntities, dispatch) => {
  if (wikidataEntities.length === 0) { return; }
  const qNumbers = _.map(wikidataEntities, 'title')
                     .filter(isEntityTitle)
                     .map(CourseUtils.removeNamespace);
  _.chunk(qNumbers, 30).forEach((someQNumbers) => {
    fetchWikidataLabelsPromise(someQNumbers)
      .then((resp) => {
        dispatch({
          type: types.RECEIVE_WIKIDATA_LABELS,
          data: resp,
          language: I18n.locale
        });
      });
  });
};



export const fetchWikidataLabelsForArticles = (articles, dispatch) => {
  const wikidataEntities = _.filter(articles, { project: 'wikidata' });
  fetchWikidataLabels(wikidataEntities, dispatch);
};

export const fetchWikidataLabelsForRevisions = (revisions, dispatch) => {
  const wikidataEntities = _.filter(revisions, { wiki: { project: 'wikidata' } });
  fetchWikidataLabels(wikidataEntities, dispatch);
};
