import {
  RECEIVE_CAMPAIGNS,
  SORT_CAMPAIGNS
} from '../constants/campaigns.js';

const initialState = {
  campaigns: [],
  isLoaded: false
};

export default function campaigns(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_CAMPAIGNS:
      return {
        campaigns: action.data.course.campaigns,
        isLoaded: true
      };
    // case SORT_CAMPAIGNS:
    default:
      return state;
  }
}
