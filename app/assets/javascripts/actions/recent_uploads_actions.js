import { RECEIVE_RECENT_UPLOADS, SORT_RECENT_UPLOADS, API_FAIL } from '../constants';
import API from '../utils/api.js';

export const fetchRecentUploads = (opts = {}) => (dispatch) => {
  return (
    API.fetchRecentUploads(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_RECENT_UPLOADS,
          data: resp,
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortRecentUploads = key => ({ type: SORT_RECENT_UPLOADS, key });
