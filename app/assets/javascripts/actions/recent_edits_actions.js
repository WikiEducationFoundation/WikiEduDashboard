import { RECEIVE_RECENT_EDITS, SORT_RECENT_EDITS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const _fetchRecentEdits = async (opts = {}) => {
  const response = await request(`/revision_analytics/recent_edits.json?scoped=${opts.scoped || false}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
};

export const fetchRecentEdits = (opts = {}) => (dispatch) => {
  return (
    _fetchRecentEdits(opts)
      .then(resp =>
        dispatch({
          type: RECEIVE_RECENT_EDITS,
          payload: {
            data: resp,
          }
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortRecentEdits = key => ({ type: SORT_RECENT_EDITS, key: key });
