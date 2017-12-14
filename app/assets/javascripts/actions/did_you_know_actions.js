import { RECEIVE_DYK, API_FAIL } from "../constants";
import API from "../utils/api.js";

export const fetchDYKArticles = (opts = {}) => dispatch => {
  return (
    API.fetchDykArticles(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_DYK,
          payload: {
            data: resp,
          }
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
