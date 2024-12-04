import * as types from '../constants';
import API from '../utils/api.js';
import { getRevisionRange } from '../utils/mediawiki_revisions_utils';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch fucntion —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function fetchArticleDetails(articleId, courseId) {
  return function (dispatch) {
    return API.fetchArticleDetails(articleId, courseId)
      .then((response) => {
        // eslint-disable-next-line no-console
        const details = response.article_details;
        return getRevisionRange(details.apiUrl, details.articleTitle, details.editors, details.startDate, details.endDate)
          // eslint-disable-next-line no-console
          .then(revisionRange => dispatch({ type: types.RECEIVE_ARTICLE_DETAILS, articleId, details, revisionRange }));
      })
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export function updateArticleTrackedStatus(articleId, courseId, tracked) {
  return function (dispatch) {
    return API.updateArticleTrackedStatus(articleId, courseId, tracked).then(response => (dispatch({
      type: types.UPDATE_ARTICLE_TRACKED_STATUS,
      articleId,
      tracked,
      data: response
    }))).catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}
