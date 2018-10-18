import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import { fetchWikidataLabelsForArticles } from './wikidata_actions';

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


export const fetchArticles = (courseId, limit) => (dispatch) => {
  return (
    fetchArticlesPromise(courseId, limit)
      .then((resp) => {
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
        fetchWikidataLabelsForArticles(resp.course.articles, dispatch);
       })
      .catch(response => dispatch({ type: types.API_FAIL, data: response }))
  );
};

export const sortArticles = key => ({ type: types.SORT_ARTICLES, key: key });

export const filterArticles = wiki => ({ type: types.SET_PROJECT_FILTER, wiki: wiki });

export const filterNewness = newness => ({ type: types.SET_NEWNESS_FILTER, newness });
