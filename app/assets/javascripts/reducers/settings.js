import {
  SET_ADMIN_USERS, SET_SPECIAL_USERS, SET_DEFAULT_CAMPAIGN,
  SUBMITTING_NEW_ADMIN, REVOKING_ADMIN, SWITCH_DEFAULT_CAMPAIGN,
  SUBMITTING_NEW_SPECIAL_USER, REVOKING_SPECIAL_USER,
} from '../constants/settings';

const initialState = {
  adminUsers: [],
  specialUsers: {},
  defaultcampaign: false,
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
  },
  swithDashboard: false
};

const settings = (state = initialState, action) => {
  switch (action.type) {
    case SET_ADMIN_USERS:
      return Object.assign({}, state, { adminUsers: action.data.admins });
    case SET_SPECIAL_USERS:
      return Object.assign({}, state, { specialUsers: action.data.special_users });
    case SET_DEFAULT_CAMPAIGN:
      return Object.assign({}, state, { defaultcampaign: action.data.default_campaign_enable });
    case SUBMITTING_NEW_ADMIN:
      return Object.assign({}, state, { submittingNewAdmin: action.data.submitting });
    case REVOKING_ADMIN:
      return Object.assign({}, state, { revokingAdmin: action.data.revoking });
    case SUBMITTING_NEW_SPECIAL_USER:
      return Object.assign({}, state, { submittingNewSpecialUser: action.data.submitting });
    case REVOKING_SPECIAL_USER:
      return Object.assign({}, state, { revokingSpecialUser: action.data.revoking });
    case SWITCH_DEFAULT_CAMPAIGN:
      return Object.assign({}, state, { swithDashboard: action.data.switch_campaign });
    default:
      return state;
  }
};

export default settings;
