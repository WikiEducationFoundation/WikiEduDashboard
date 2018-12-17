import {
  SET_ADMIN_USERS, SET_SPECIAL_USERS,
  SUBMITTING_NEW_ADMIN, REVOKING_ADMIN,
  SUBMITTING_NEW_SPECIAL_USER, REVOKING_SPECIAL_USER,
} from '../constants/settings';

const initialState = {
  adminUsers: [],
  specialUsers: {},
  fetchingUsers: false,
  submittingNewAdmin: false,
  submittingNewSpecialUser: false,
  revokingAdmin: {
    status: false,
    username: null,
  },
  revokingSpecialUser: {
    status: false,
    username: null,
  }
};

const settings = (state = initialState, action) => {
  switch (action.type) {
    case SET_ADMIN_USERS:
      return Object.assign({}, state, { adminUsers: action.data.admins });
    case SET_SPECIAL_USERS:
      return Object.assign({}, state, { specialUsers: action.data.special_users });
    case SUBMITTING_NEW_ADMIN:
      return Object.assign({}, state, { submittingNewAdmin: action.data.submitting });
    case REVOKING_ADMIN:
      return Object.assign({}, state, { revokingAdmin: action.data.revoking });
    case SUBMITTING_NEW_SPECIAL_USER:
      return Object.assign({}, state, { submittingNewSpecialUser: action.data.submitting });
    case REVOKING_SPECIAL_USER:
      return Object.assign({}, state, { revokingSpecialUser: action.data.revoking });
    default:
      return state;
  }
};

export default settings;
