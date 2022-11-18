import * as types from '../constants';
import API from '../utils/api.js';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch fucntion —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function submitBadWorkAlert(data) {
  return function (dispatch) {
    dispatch({ type: types.BAD_WORK_ALERT_SUBMITTED });
    return API.createAlert(data, 'BadWorkAlert')
      .then(() => (dispatch({ type: types.BAD_WORK_ALERT_CREATED })))
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export const resetBadWorkAlert = () => ({ type: types.RESET_BAD_WORK_ALERT });

export function submitReviewRequestAlert({ assignment, course }) {
  const data = {
    user_id: assignment.user_id,
    course_id: course.id,
    message: `Ready for review: <a href="${assignment.sandbox_url}/bibliography">${assignment.sandbox_url}/bibliography</a>`
  };

  return function (dispatch) {
    dispatch({ type: types.REVIEW_REQUEST_ALERT_SUBMITTED });
    return API.createAlert(data, 'ReviewRequestAlert')
      .then(() => (dispatch({ type: types.REVIEW_REQUEST_ALERT_CREATED })))
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export function submitNeedHelpAlert(data) {
  return function (dispatch, getState) {
    // Don't double-submit.
    if (getState().needHelpAlert.submitting) { return; }

    dispatch({ type: types.NEED_HELP_ALERT_SUBMITTED });
    return API.createAlert(data, 'NeedHelpAlert')
      .then(() => (dispatch({ type: types.NEED_HELP_ALERT_CREATED })))
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export const resetNeedHelpAlert = () => ({ type: types.RESET_NEED_HELP_ALERT });

const fetchResponseToJSON = (res) => {
  if (res.ok && res.status === 200) {
    return res.json();
  }
  return Promise.reject(res);
};

const resolveAlertPromise = (alertId) => {
  return request(`/alerts/${alertId}/resolve.json`, {
    credentials: 'include'
  }).then(fetchResponseToJSON)
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

export const handleResolveAlert = alertId => (dispatch) => {
  return (
    resolveAlertPromise(alertId)
      .then(() => {
        dispatch({
          type: types.RESOLVE_ALERT,
          alertId
        });
      })
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })))
  );
};

const fetchAlertsPromise = (url) => {
  return request(url, {
    credentials: 'include'
  }).then(fetchResponseToJSON)
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

const fetchAdminAlertsPromise = () => fetchAlertsPromise('/alerts_list.json');

const fetchCampaignAlertsPromise = slug => fetchAlertsPromise(`/campaigns/${slug}/alerts.json`);

const fetchTaggedCourseAlertsPromise = tag => fetchAlertsPromise(`/tagged_courses/${tag}/alerts.json`);

const fetchCourseAlertsPromise = slug => fetchAlertsPromise(`/courses/${slug}/alerts.json`);

const receiveAlerts = dispatch => data => dispatch({ type: types.RECEIVE_ALERTS, data });

const apiFail = dispatch => response => dispatch({ type: types.API_FAIL, data: response });

export const fetchAdminAlerts = () => (dispatch) => {
  return (
    fetchAdminAlertsPromise()
      .then(receiveAlerts(dispatch))
      .catch(apiFail(dispatch))
  );
};

export const fetchCampaignAlerts = campaignSlug => (dispatch) => {
  return (
    fetchCampaignAlertsPromise(campaignSlug)
      .then(receiveAlerts(dispatch))
      .catch(apiFail(dispatch))
  );
};

export const fetchTaggedCourseAlerts = tag => (dispatch) => {
  return (
    fetchTaggedCourseAlertsPromise(tag)
      .then(receiveAlerts(dispatch))
      .catch(apiFail(dispatch))
  );
};

export const fetchCourseAlerts = courseSlug => (dispatch) => {
  return (
    fetchCourseAlertsPromise(courseSlug)
      .then(receiveAlerts(dispatch))
      .catch(apiFail(dispatch))
  );
};


export const sortAlerts = key => ({ type: types.SORT_ALERTS, key: key });

export const filterAlerts = selectedFilters => ({ type: types.FILTER_ALERTS, selectedFilters: selectedFilters });
