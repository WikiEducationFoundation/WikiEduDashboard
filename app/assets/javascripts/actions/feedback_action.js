import * as types from '../constants/action_types.js';
import ApiFailAction from './api_fail_action.js';
import API from '../utils/api.js';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch fucntion —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function fetchFeedback(articleTitle) {
  return function (dispatch) {
    return API.fetchFeedback(articleTitle)
      .then((resp) => {
        dispatch({ type: types.RECEIVE_ARTICLE_FEEDBACK, data: resp, articleTitle: articleTitle });
      }
      )
      // TODO: The Flux stores still handle API failures, so we delegate to a
      // Flux action. Once all API_FAIL actions can be handled by Redux, we can
      // replace this with a regular action dispatch.
      .catch(response => (ApiFailAction.fail(response)));
  };
}
