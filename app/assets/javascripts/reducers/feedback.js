import { RECEIVE_ARTICLE_FEEDBACK } from '../constants/action_types.js';

const initialState = {};

export default function feedback(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLE_FEEDBACK: {
      const newState = { ...state };
      newState[action.articleTitle] = action.data;
      return newState;
    }
    default:
      return state;
  }
}
