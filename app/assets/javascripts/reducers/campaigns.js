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

// these keys are to be sorted in descending order on first click
const SORT_DESCENDING = {
  course_count: true,
  new_article_count: true,
  article_count: true,
  word_count: true,
  references_count: true,
  view_sum: true,
  user_count: true,
};

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
      const sorted = sortByKey(
        state.all_campaigns,
        action.key,
        state.sort.sortKey,
        SORT_DESCENDING[action.key]
      );
      return {
        ...state,
        all_campaigns: sorted.newModels,
        sort: {
          sortKey: sorted.newKey,
          key: action.key
        },
      };
    }
    default:
      return state;
  }
}
