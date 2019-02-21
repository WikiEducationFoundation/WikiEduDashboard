import API from '../utils/api.js';
import { RECEIVE_INITIAL_CAMPAIGN, CREATED_COURSE, RECEIVE_COURSE_CLONE, API_FAIL } from '../constants';
import fetch from 'cross-fetch';
import logErrorMessage from '../utils/log_error_message';

const fetchCampaignPromise = (slug) => {
  return fetch(`/campaigns/${slug}.json`, {
    credentials: 'include'
  }).then((res) => {
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

export const fetchCampaign = slug => (dispatch) => {
  return fetchCampaignPromise(slug)
    .then(resp => dispatch({ type: RECEIVE_INITIAL_CAMPAIGN, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const submitCourse = (course, failureCallback) => (dispatch) => {
  return API.saveCourse(course, null)
    .then(resp => dispatch({ type: CREATED_COURSE, data: resp }))
    .catch((resp) => {
      failureCallback();
      dispatch({ type: API_FAIL, data: resp });
    });
};

export const cloneCourse = courseId => (dispatch) => {
  return API.cloneCourse(courseId)
    .then(resp => dispatch({ type: RECEIVE_COURSE_CLONE, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
