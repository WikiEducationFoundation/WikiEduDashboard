import {
  RECEIVE_CAMPAIGNS,
  RECEIVE_ALL_CAMPAIGNS
} from '../constants/campaigns.js';

const initialState = {
  campaigns: [],
  all_campaigns: [],
  isLoaded: false
};

export default function campaigns(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_CAMPAIGNS:
      return {
        campaigns: action.data.course.campaigns,
        isLoaded: true
      };
    case RECEIVE_ALL_CAMPAIGNS:
      return {
        all_campaigns: action.data.campaigns
      };
    default:
      return state;
  }
}
