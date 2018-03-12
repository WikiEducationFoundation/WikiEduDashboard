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

export const fetchArticles = (courseId, limit) => dispatch => {
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
       })
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })))
  );
};

export const sortArticles = key => ({ type: types.SORT_ARTICLES, key: key });

export const filterArticles = wiki => ({ type: types.SET_PROJECT_FILTER, wiki: wiki });
