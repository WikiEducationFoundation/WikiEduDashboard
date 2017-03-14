import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

const ProfileActions = Flux.createActions({
  fetch_stats(username) {
    return API.fetchStatsData(username)
      .then(resp => ({ actionType: 'RECEIVE_STATISTICS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export default ProfileActions;
