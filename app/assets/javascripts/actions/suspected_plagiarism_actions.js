import { RECEIVE_SUSPECTED_PLAGIARISM, SORT_SUSPECTED_PLAGIARISM, API_FAIL } from '../constants';
import API from '../utils/api.js';

export const fetchSuspectedPlagiarism = (opts = {}) => (dispatch) => {
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

export const sortSuspectedPlagiarism = key => ({ type: SORT_SUSPECTED_PLAGIARISM, key: key });
