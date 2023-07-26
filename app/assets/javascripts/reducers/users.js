import { RECEIVE_USERS, SORT_USERS, ADD_USER, REMOVE_USER } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  users: [],
  sort: {
    sortKey: null,
    key: 'last_name',
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
      // Get the sorting key from the Redux store
      let sort_key = state.sort.key;

       // Initialize a variable to hold the user list. If there are existing users in the state,
      //  use that list; otherwise, use the user list from the action data.
      let user_list = state.users.length ? state.users : action.data.course.users;

       // Check if the user list is empty in the state and if any user in the action data has 'real_name'
       if (!state.users.length && action.data.course.users.some(user => user.real_name)) {
         // Perform data transformation on the user list: Split 'real_name' into 'first_name' and the rest of the name ('rest')
         user_list = action.data.course.users.map((user) => {
           const [first_name, ...rest] = (user.real_name?.trim().toLowerCase() || '').split(' ');
            // Return the user object with updated 'first_name' and 'last_name' properties
           return { ...user, first_name, last_name: rest.join(' ') };
         });
       } else if (!state?.users.length) {
         // If there are no users in the state and none of the users in the action data have 'real_name',
        // set the sorting key to 'username'
         sort_key = 'username';
        }

      // Sort the 'user_list' array based on the 'sort_key' if the user list is empty in the state.
      if (!state.users.length) user_list = sortByKey(user_list, sort_key, null, SORT_DESCENDING[sort_key]);

    return {
      ...state,
      users: user_list.newModels ? user_list.newModels : user_list,
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
