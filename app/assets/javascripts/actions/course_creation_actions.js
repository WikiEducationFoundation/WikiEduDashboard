import API from '../utils/api.js';
import request, { ensureOk } from '../utils/request';

import { RECEIVE_INITIAL_CAMPAIGN, CREATED_COURSE, RECEIVE_COURSE_CLONE, API_FAIL } from '../constants';

const fetchCampaignPromise = async (slug) => {
  const response = await request(`/campaigns/${slug}.json`);
  await ensureOk(response);
  return response.json();
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

export const cloneCourse = (courseId, campaign, copyAssignments) => (dispatch) => {
  return API.cloneCourse(courseId, campaign, copyAssignments)
    .then(resp => dispatch({ type: RECEIVE_COURSE_CLONE, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
