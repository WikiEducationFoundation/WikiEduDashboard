import { RECEIVE_RECENT_UPLOADS, API_FAIL } from "../constants";
import API from "../utils/api.js";

export const fetchRecentUploads = (opts = {}) => dispatch => {
  return (
    API.fetchRecentUploads(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_RECENT_UPLOADS,
          payload: {
            data: resp,
          }
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
