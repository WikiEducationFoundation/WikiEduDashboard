import { RECEIVE_USERS, SORT_USERS, ADD_USER, REMOVE_USER } from '../constants';
import { sortByKey, transformUsers } from '../utils/model_utils';

const initialState = {
  users: [],
  sort: {
    sortKey: null,
    key: null,
    previousSortKey: null,
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
      // Get the sorting key from if available from Redux store or else use last_name
      let sort_key = state.sort.key || 'last_name';

      // Initialize a variable to hold the user list.
      let user_list = action.data.course.users;

       // Check if any user in the user_list has 'real_name'
       if (user_list.some(user => user.real_name)) {
         // If any users have 'real_name', transform the 'real_name' into separate
         // 'first_name' and 'last_name' properties and update the user list
         user_list = transformUsers(user_list);
        } else if (!state.sort.key) {
          // If there are no users with real_name and key in the store is null then set sort_key by username
          sort_key = 'username';
        }

        // Sort the 'user_list' array based on the 'sort_key'
        user_list = sortByKey(user_list, sort_key, state.sort.previousKey, SORT_DESCENDING[sort_key]);
    return {
      ...state,
      users: user_list.newModels, // Update 'users' with the sorted user list.
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
          key: action.key,
          // store the previous sortKey to use if the instructor switches between tabs and comes back to the students/editors tab
          previousSortKey: state.sort.sortKey,
        }
      };
    }

    default:
      return state;
  }
}
