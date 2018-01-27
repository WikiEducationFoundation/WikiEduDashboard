import { RECEIVE_USERS, SORT_USERS, ADD_USER, REMOVE_USER } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  users: [],
  sortKey: null,
  isLoaded: false
};

const SORT_DESCENDING = {
  character_sum_ms: true,
  character_sum_us: true,
  character_sum_draft: true,
  recent_edits: true
};

export default function users(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USERS:
    case ADD_USER:
    case REMOVE_USER:
      return {
        users: action.data.course.users,
        sortKey: null,
        isLoaded: true
      };

    case SORT_USERS: {
      const newState = { ...state };
      const sorted = sortByKey(newState.users, action.key, state.sortKey, SORT_DESCENDING[action.key]);
      newState.users = sorted.newModels;
      newState.sortKey = sorted.newKey;
      return newState;
    }

    default:
      return state;
  }
}
