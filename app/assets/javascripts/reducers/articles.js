import _ from 'lodash';
import { RECEIVE_ARTICLES, SORT_ARTICLES } from '../constants';

const initialState = {
  articles: [],
  limit: 500,
  limitReached: false,
  sortKey: null
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
      if (action.key === state.sortKey) {
        newState.articles = _.sortBy(state.articles, action.key).reverse();
        newState.sortKey = null;
      } else {
        newState.articles = _.sortBy(state.articles, action.key);
        newState.sortKey = action.key;
      }
      return newState;
    }
    default:
      return state;
  }
}
