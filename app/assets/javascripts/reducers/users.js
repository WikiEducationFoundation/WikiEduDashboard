import { RECEIVE_USERS, SORT_USERS, ADD_USER, REMOVE_USER } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  users: [],
  sort: {
    sortKey: null,
    key: null,
  },
  isLoaded: false
};

const SORT_DESCENDING = {
  character_sum_ms: true,
  character_sum_us: true,
  character_sum_draft: true,
  recent_revisions: true,
  total_uploads: true,

};

export default function users(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USERS:
    case ADD_USER:
    case REMOVE_USER:
      return {
        ...state,
        users: action.data.course.users,
        isLoaded: true
      };

    case SORT_USERS: {
      const newState = { ...state };
      const sorted = sortByKey(newState.users, action.key, state.sort.sortKey, SORT_DESCENDING[action.key]);
      newState.users = sorted.newModels;
      newState.sort.sortKey = sorted.newKey;
      newState.sort.key = action.key;
      return newState;
    }

    default:
      return state;
  }
}
