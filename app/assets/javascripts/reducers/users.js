import { RECEIVE_USERS, SORT_USERS, ADD_USER, REMOVE_USER } from '../constants';
import { sortByKey, transformUsers } from '../utils/model_utils';

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
      // Get the sorting key if available from Redux store or else use last_name
      let sort_key = state.sort.key || 'last_name';
      /* Use the previousKey to determine the directions of sorting.
         Note: Direction of the sorting only matter after the user/instructor sort the students/editors
         list using the dropdown menu or one of the student/editors header and then navigates between
         tabs and then a data refresh occurs(usually after one minute).
      */
      let previousKey = null;
      // Initialize a variable to hold the user list.
      let user_list = action.data.course.users;

      // Transform the 'real_name' in user_list into separate 'first_name' and 'last_name' properties
      // if 'real_name' is available by using transformUsers
      user_list = transformUsers(user_list);

      // If there are no users with last_name and key in the store is null then set sort_key by username
      if (!state.sort.key && !user_list.some(user => user.last_name)) {
        sort_key = 'username';
      }

      /* If 'key' in the store is not null which implies instructor/user had sort the student/editors list either using
      the dropdown menu or one of the student/editor tab and if 'sortKey' state is null it means sorting was done in
      reverse so set the previousKey to the 'sort_key' or else null. */
      if (state.sort.key) { previousKey = state.sort.sortKey ? null : sort_key; }

      // Sort the 'user_list' array based on the 'sort_key'
      user_list = sortByKey(user_list, sort_key, previousKey, SORT_DESCENDING[sort_key]);

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
        }
      };
    }

    default:
      return state;
  }
}
