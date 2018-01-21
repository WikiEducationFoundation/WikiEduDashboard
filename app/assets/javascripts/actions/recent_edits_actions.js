import { RECEIVE_RECENT_EDITS, API_FAIL } from "../constants";
import API from "../utils/api.js";

export const fetchRecentEdits = (opts = {}) => dispatch => {
  return (
    API.fetchRecentEdits(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_RECENT_EDITS ,
          payload: {
            data: resp,
          }
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};