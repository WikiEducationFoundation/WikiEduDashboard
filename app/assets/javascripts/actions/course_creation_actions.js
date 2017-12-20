import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';
import { UPDATE_COURSE, CREATED_COURSE, API_FAIL } from '../constants';

export const CourseCreationActions = Flux.createActions({
  fetchCampaign(slug) {
    return API.fetchCampaign(slug)
      .then(resp => ({ actionType: 'RECEIVE_INITIAL_CAMPAIGN', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export const updateCourse = course => ({ type: UPDATE_COURSE, course });

export const submitCourse = (course, failureCallback) => dispatch => {
  return API.saveCourse(course, null)
    .then((resp) => (dispatch({ type: CREATED_COURSE, data: resp })))
    .catch((resp) => {
      failureCallback();
      dispatch({ type: API_FAIL, data: resp });
    });
};
