import { RECEIVE_SUSPECTED_PLAGIARISM, API_FAIL } from "../constants";

const _fetchSuspectedPlagiarism = (opts = {}) => {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'GET',
        url: `/revision_analytics/recent_edits.json?scoped=${opts.scoped || false}`,
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  };

export const _fetchSuspectedPlagiarism = (opts = {}) => dispatch => {
  return (
    _fetchSuspectedPlagiarism(opts)
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
