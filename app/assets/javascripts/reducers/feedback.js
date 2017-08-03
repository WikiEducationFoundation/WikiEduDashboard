import { RECEIVE_ARTICLE_FEEDBACK, POST_USER_FEEDBACK } from '../constants/action_types.js';

const initialState = {};

export default function feedback(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLE_FEEDBACK: {
      const newState = { ...state };
      newState[action.assignmentId] = action.data;
      return newState;
    }
    case POST_USER_FEEDBACK: {
      const newState = { ...state };
      newState[action.assignmentId].custom.push({ message: action.feedback, messageId: action.messageId });
      return newState;
    }
    default:
      return state;
  }
}

