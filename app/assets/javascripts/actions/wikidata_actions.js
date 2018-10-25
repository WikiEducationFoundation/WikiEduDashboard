import _ from 'lodash';
import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';

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


const fetchWikidataLabels = (wikidataEntities, dispatch) => {
  if (wikidataEntities.length === 0) { return; }

  const qNumbers = _.map(wikidataEntities, 'title');
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
