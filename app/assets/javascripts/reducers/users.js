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
      let updatedUsers;
      // Get the user list from the action's data
      const user_list = action.data.course.users;

      // Check if at least one user has a 'real_name', if so, perform data transformation
       if (user_list.some(user => user.real_name)) {
         updatedUsers = user_list.map((user) => {
          // Split 'real_name' into 'first_name' and the rest of the name ('rest')
           const [first_name, ...rest] = (user.real_name?.trim().toLowerCase() || '').split(' ');
           // Return the user object with updated 'first_name' and 'last_name' properties
           return { ...user, first_name, last_name: rest.join(' ') };
         });
       } else {
         // If no user has 'real_name', use the original user list as-is and sort by 'username'
         updatedUsers = action.data.course.users;
         sort_key = state.sort.key === 'last_name' ? 'username' : state.sort.key;
        }

      // Sort the 'updatedUsers' array based on the 'sort_key'
      const sorted = sortByKey(updatedUsers, sort_key, null, SORT_DESCENDING[sort_key]);

    return {
      ...state,
      users: sorted.newModels,
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
