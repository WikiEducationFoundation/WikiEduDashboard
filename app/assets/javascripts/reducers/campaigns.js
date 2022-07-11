import {
  RECEIVE_COURSE_CAMPAIGNS,
  RECEIVE_ALL_CAMPAIGNS,
  ADD_CAMPAIGN,
  DELETE_CAMPAIGN,
  SORT_CAMPAIGNS_WITH_STATS,
  RECEIVE_CAMPAIGNS_WITH_STATS,
  SORT_ALL_CAMPAIGNS
} from '../constants/campaigns.js';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  campaigns: [],
  all_campaigns: [],
  isLoaded: false,
  all_campaigns_loaded: false,
  sort: {
    key: null,
    sortKey: null,
  },
};

export default function campaigns(state = initialState, action) {
  switch (action.type) {
    case ADD_CAMPAIGN:
    case DELETE_CAMPAIGN:
    case RECEIVE_COURSE_CAMPAIGNS: {
      const newState = {
        ...state,
        campaigns: action.data.course.campaigns,
        isLoaded: true
      };
      return newState;
    }
    case RECEIVE_ALL_CAMPAIGNS:
    case RECEIVE_CAMPAIGNS_WITH_STATS: {
      const newState = {
        ...state,
        all_campaigns: action.data.campaigns,
        all_campaigns_loaded: true
      };
      return newState;
    }
    case SORT_CAMPAIGNS_WITH_STATS:
    case SORT_ALL_CAMPAIGNS: {
      const desc = action.key === state.sort.sortKey;
      const newCampaigns = sortByKey(state.all_campaigns, action.key, null, desc);
      return {
        ...state,
        all_campaigns: newCampaigns.newModels,
        sort: {
          sortKey: desc ? null : action.key,
          key: action.key
        },
      };
    }
    default:
      return state;
  }
}
