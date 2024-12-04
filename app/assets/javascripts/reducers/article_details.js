import { RECEIVE_ARTICLE_DETAILS } from '../constants';

const initialState = {};

export default function articleDetails(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLE_DETAILS: {
      const newState = { ...state };
      newState[action.articleId] = { ...action.details, ...action.revisionRange };
      return newState;
    }
    default:
      return state;
  }
}
