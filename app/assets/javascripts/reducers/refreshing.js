import { DONE_REFRESHING_DATA, REFRESHING_DATA } from '../constants';

const initialState = {
  refreshing: false
};

export default function users(state = initialState, action) {
  switch (action.type) {
    case REFRESHING_DATA: {
      return {
        ...state,
        refreshing: true
      };
    }
    case DONE_REFRESHING_DATA: {
      return {
        ...state,
        refreshing: false
      };
    }

    default:
      return state;
  }
}

