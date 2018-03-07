import { sortByKey } from '../utils/model_utils';
import { RECEIVE_ARTICLES, SORT_ARTICLES } from '../constants';

const initialState = {
  articles: [],
  limit: 500,
  limitReached: false,
  sortKey: 'character_sum'
};

const SORT_DESCENDING = {
  rating_num: true,
  title: true,
  character_sum: true,
  view_count: true
};


const isLimitReached = (revs, limit) => {
  return (revs.length < limit);
};

export default function articles(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLES:
      return {
        articles: action.data.course.articles,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.articles, action.limit)
      };
    case SORT_ARTICLES: {
      const newState = { ...state };
      const sorted = sortByKey(newState.articles, action.key, state.sortKey, SORT_DESCENDING[action.key]);
      newState.users = sorted.newModels;
      newState.sortKey = sorted.newKey;
      return newState;
    }
    default:
      return state;
  }
}
