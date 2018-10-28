import * as types from '../constants';
import API from '../utils/api.js';
import logErrorMessage from '../utils/log_error_message';
import fetch from 'isomorphic-fetch';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch fucntion —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function submitNeedHelpAlert(data) {
  return function (dispatch) {
    dispatch({ type: types.NEED_HELP_ALERT_SUBMITTED });
    return API.createNeedHelpAlert(data)
      .then(() => (dispatch({ type: types.NEED_HELP_ALERT_CREATED })))
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export const resetNeedHelpAlert = () => ({ type: types.RESET_NEED_HELP_ALERT });

const fetchAlertsPromise = (campaignSlug) => {
  return fetch(`/campaigns/${campaignSlug}/alerts.json`)
    .then((res) => {
      if (res.ok && res.status === 200) {
        return res.json();
      }
      return Promise.reject(res);
    })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

export const fetchAlerts = campaignSlug => (dispatch) => {
  return (
    fetchAlertsPromise(campaignSlug)
      .then((data) => {
        dispatch({
          type: types.RECEIVE_ALERTS,
          data
        });
      })
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })))
  );
};

export const sortAlerts = key => ({ type: types.SORT_ALERTS, key: key });

export const filterAlerts = selectedFilters => ({ type: types.FILTER_ALERTS, selectedFilters: selectedFilters });
