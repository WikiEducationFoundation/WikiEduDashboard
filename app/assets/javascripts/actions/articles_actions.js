import _ from 'lodash';
import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchArticlesPromise = (courseId, limit) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/articles.json?limit=${limit}`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

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

const fetchWikidataLabels = (articles, dispatch) => {
  const wikidataEntities = _.filter(articles, { project: 'wikidata' });
  if (wikidataEntities.length === 0) { return; }
  const qNumbers = _.map(wikidataEntities, 'title');
  _.chunk(qNumbers, 30).forEach(someQNumbers => {
    fetchWikidataLabelsPromise(someQNumbers)
      .then(resp => {
        dispatch({
          type: types.RECEIVE_WIKIDATA_LABELS,
          data: resp,
          language: I18n.locale
        });
      });
  });
};

export const fetchArticles = (courseId, limit) => (dispatch) => {
  return (
    fetchArticlesPromise(courseId, limit)
      .then(resp => {
        dispatch({
          type: types.RECEIVE_ARTICLES,
          data: resp,
          limit: limit
        });
        dispatch({
          type: types.SORT_ARTICLES,
          key: 'character_sum'
        });
        // Now that we received the articles data, query wikidata.org for the labels
        // of any Wikidata entries that are among the articles.
        fetchWikidataLabels(resp.course.articles, dispatch);
       })
      .catch(response => dispatch({ type: types.API_FAIL, data: response }))
  );
};

export const sortArticles = key => ({ type: types.SORT_ARTICLES, key: key });

export const filterArticles = wiki => ({ type: types.SET_PROJECT_FILTER, wiki: wiki });
