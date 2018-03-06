import * as types from '../constants';
import API from '../utils/api.js';
import logErrorMessage from '../utils/log_error_message';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch fucntion —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function fetchArticleDetails(articleId, courseId) {
  return function (dispatch) {
    return API.fetchArticleDetails(articleId, courseId)
      .then(response => (dispatch({
        type: types.RECEIVE_ARTICLE_DETAILS,
        articleId: articleId,
        data: response
      })))
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

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
      .then(resp =>
        dispatch({
          type: types.RECEIVE_ARTICLES,
          data: resp,
          limit: limit
        }))
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })))
  );
};
