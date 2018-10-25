import { RECEIVE_RECENT_EDITS, SORT_RECENT_EDITS, API_FAIL } from '../constants';

const _fetchRecentEdits = (opts = {}) => {
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
