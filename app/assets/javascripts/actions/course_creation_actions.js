import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';
import { UPDATE_COURSE } from '../constants';

export const CourseCreationActions = Flux.createActions({
  fetchCampaign(slug) {
    return API.fetchCampaign(slug)
      .then(resp => ({ actionType: 'RECEIVE_INITIAL_CAMPAIGN', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export const updateCourse = course => ({ type: UPDATE_COURSE, course });
