
import API from '../utils/api.js';
import { RECEIVE_INITIAL_CAMPAIGN, UPDATE_COURSE, CREATED_COURSE, RECEIVE_COURSE_CLONE, API_FAIL } from '../constants';

const fetchCampaignPromise = slug => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: `/campaigns/${slug}.json`,
      success(data) {
        return res(data);
      }
    })
    .fail(obj => rej(obj))
  );
};

export const fetchCampaign = slug => dispatch => {
  return fetchCampaignPromise(slug)
    .then(resp => dispatch({ type: RECEIVE_INITIAL_CAMPAIGN, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const updateCourse = course => ({ type: UPDATE_COURSE, course });

export const submitCourse = (course, failureCallback) => dispatch => {
  return API.saveCourse(course, null)
    .then(resp => dispatch({ type: CREATED_COURSE, data: resp }))
    .catch(resp => {
      failureCallback();
      dispatch({ type: API_FAIL, data: resp });
    });
};

export const cloneCourse = courseId => dispatch => {
  return API.cloneCourse(courseId)
    .then(resp => dispatch({ type: RECEIVE_COURSE_CLONE, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
