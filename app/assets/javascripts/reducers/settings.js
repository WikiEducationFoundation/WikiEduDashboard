import { SET_ADMIN_USERS, SUBMITTING_NEW_ADMIN } from '../constants/settings';

const initialState = {
  adminUsers: [],
  fetchingUsers: false,
  submittingNewAdmin: false,
  RevokingAdmin: false
};

const settings = (state = initialState, action) => {
  switch (action.type) {
    case SET_ADMIN_USERS:
      return Object.assign({}, initialState, { adminUsers: action.data.users });
    case SUBMITTING_NEW_ADMIN:
      return Object.assign({}, initialState, { submittingNewAdmin: action.data.submitting });
    default:
      return state;
  }
};

export default settings;

