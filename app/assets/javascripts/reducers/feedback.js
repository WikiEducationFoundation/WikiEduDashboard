import { FEEDBACK } from '../constants/action_types.js';

const initialState = {};

export default function feedback(state = initialState, action) {
  switch (action.type) {
    case FEEDBACK: {
      const newState = { ...state };
      newState[action.articleId] = action.data.suggestions;
      return newState;
    }
    default:
      return state;
  }
}
