import { chunk, map, join, filter } from 'lodash-es';
import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import CourseUtils from '../utils/course_utils';
import request from '../utils/request';
import { stringify } from 'query-string';

const wikidataApiBase = 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&origin=*';

const fetchWikidataLabelsPromise = async (qNumbers) => {
  const idsParam = join(qNumbers, '|');
  const query = {
    ids: idsParam,
    props: 'labels',
    languages: `${I18n.locale}|mul|en`
  };
  const response = await request(`${wikidataApiBase}&${stringify(query)}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

// This takes a Wikidata page title and checks whether it looks like
// an *entity*, which could be in the Property (P), Lexeme (L), or main (Q) namespace.
// Entities have labels, while other pages are conventional wiki pages.
// Requesting the labels for an entitiy that doesn't exist will result in an API error,
// so this is used to filter out edits to (for example) WikiProject pages.
const isEntityTitle = (title) => {
  const isQItem = !/:/.test(title); // no colon means mainspace, aka Q item
  const isPropertyOrLexeme = /(Property|Lexeme):/.test(title);// Property or Lexeme namespace, aka P or L
  return isQItem || isPropertyOrLexeme;
};

export const fetchWikidataLabels = (wikidataEntities, dispatch) => {
  if (wikidataEntities.length === 0) { return; }
  const qNumbers = map(wikidataEntities, 'title')
    .filter(isEntityTitle)
    .map(CourseUtils.removeNamespace);
  chunk(qNumbers, 30).forEach((someQNumbers) => {
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
  const wikidataEntities = filter(articles, { project: 'wikidata' });
  fetchWikidataLabels(wikidataEntities, dispatch);
};

export const fetchWikidataLabelsForRevisions = (revisions, dispatch) => {
  const wikidataEntities = filter(revisions, { wiki: { project: 'wikidata' } });
  fetchWikidataLabels(wikidataEntities, dispatch);
};
