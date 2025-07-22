import API from '../utils/api.js';
import { RECEIVE_USER_PROFILE_STATS, API_FAIL } from '../constants';

export const fetchStats = username => (dispatch) => {
  return API.fetchUserProfileStats(username)
    .then(resp => dispatch({ type: RECEIVE_USER_PROFILE_STATS, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
