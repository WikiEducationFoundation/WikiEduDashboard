import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

const CourseCreationActions = Flux.createActions({
  fetchCampaign(campaignId) {
    return API.fetchCampaign(campaignId)
      .then(resp => ({ actionType: 'RECEIVE_INITIAL_CAMPAIGN', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export default CourseCreationActions;
