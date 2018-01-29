import { RECEIVE_SUSPECTED_PLAGIARISM, API_FAIL } from "../constants";

export const fetchSuspectedPlagiarism = (opts = {}) => dispatch => {
  return (
    API.fetchSuspectedPlagiarism(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_SUSPECTED_PLAGIARISM,
          payload: {
            data: resp,
          }
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
