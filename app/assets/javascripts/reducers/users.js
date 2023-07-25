import { RECEIVE_USERS, SORT_USERS, ADD_USER, REMOVE_USER } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  users: [],
  sort: {
    sortKey: null,
    key: null,
  },
  isLoaded: false,
  lastRequestTimestamp: 0 // UNIX timestamp of last request - in milliseconds
};

const SORT_DESCENDING = {
  character_sum_ms: true,
  character_sum_us: true,
  character_sum_draft: true,
  recent_revisions: true,
  references_count: true,
  total_uploads: true,

};

export default function users(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USERS: {
      // Get the sorting key from the Redux store, defaulting to 'last_name' if not set
      const sort_key = state.sort.sortKey || 'last_name';
      // Transform the user data to include 'first_name' and 'last_name' properties based on 'real_name'
      const updatedUsers = action.data.course.users.map((user) => {
        const [first_name, ...rest] = (user.real_name?.trim().toLowerCase() || '').split(' ');
        return { ...user, first_name, last_name: rest.join(' ') };
      }).sort((a, b) => {
          // Compare the 'sort_key' properties (e.g., 'last_name') using 'localeCompare'
          // If the 'sort_key' values are equal or falsy, compare 'username' as a fallback
          return (a[sort_key] || '').localeCompare(b[sort_key] || '') || a.username.localeCompare(b.username);
      });
    return {
      ...state,
      users: updatedUsers,
      isLoaded: true,
      lastRequestTimestamp: Date.now()
    };
  }
    case ADD_USER:
    case REMOVE_USER:
      return {
        ...state,
        users: action.data.course.users,
        isLoaded: true
      };

    case SORT_USERS: {
      const sorted = sortByKey(state.users, action.key, state.sort.sortKey, SORT_DESCENDING[action.key]);
      return {
        ...state,
        users: sorted.newModels,
        sort: {
          sortKey: sorted.newKey,
          key: action.key
        }
      };
    }

    default:
      return state;
  }
}
