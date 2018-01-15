import { RECEIVE_USER_PROFILE_STATS } from '../constants';

const initialState = {
  stats: {},
  isLoading: true
};

export default function userProfile(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_PROFILE_STATS:
      return {
        stats: action.data,
        isLoading: false
      };
    default:
      return state;
  }
}
