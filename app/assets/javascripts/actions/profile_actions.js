import McFly from 'mcfly';
import API from '../utils/api.js';
const Flux = new McFly();

const ProfileActions = Flux.createActions({
  fetch_stats(username) {
    return API.fetchUserProfileStats(username)
      .then(resp => ({ actionType: 'RECEIVE_STATISTICS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export default ProfileActions;
