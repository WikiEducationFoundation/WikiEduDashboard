import { RECEIVE_ARTICLES } from '../constants';

const initialState = {
  articles: [],
  limit: 500,
  limitReached: false
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
    default:
      return state;
  }
}
