import ApiFailAction from "./api_fail_action.js";
import { RECEIVE_DYK } from "../constants";
import API from "../utils/api.js";

export const fetchDYKArticles = (opts = {}) => dispatch => {
  return (
    API.fetchDykArticles(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_DYK,
          payload: {
            data: resp,
          },
        }))
      // TODO: The Flux stores still handle API failures, so we delegate to a
      // Flux action. Once all API_FAIL actions can be handled by Redux, we can
      // replace this with a regular action dispatch.
      .catch(response => ApiFailAction.fail(response))
  );
};
