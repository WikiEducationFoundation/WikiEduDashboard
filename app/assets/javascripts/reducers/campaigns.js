import {
  RECEIVE_CAMPAIGNS,
  RECEIVE_ALL_CAMPAIGNS,
  ADD_CAMPAIGN,
  DELETE_CAMPAIGN
} from '../constants/campaigns.js';

const initialState = {
  campaigns: [],
  all_campaigns: [],
  isLoaded: false
};

export default function campaigns(state = initialState, action) {
  switch (action.type) {
    case ADD_CAMPAIGN:
    case DELETE_CAMPAIGN:
    case RECEIVE_CAMPAIGNS: {
      const newState = {
        ...state,
        campaigns: action.data.course.campaigns,
        isLoaded: true
        };
      return newState;
      }
    case RECEIVE_ALL_CAMPAIGNS: {
      const newState = {
        ...state,
        all_campaigns: action.data.campaigns
        };
      return newState;
      }
    default:
      return state;
  }
}
