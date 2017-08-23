import * as ActionTypes from '../constants/action_types.js';

const initialState = {};

export default function feedback(state = initialState, action) {
  switch (action.type) {
    case ActionTypes.RECEIVE_ARTICLE_FEEDBACK: {
      const newState = { ...state };
      newState[action.assignmentId] = action.data;
      return newState;
    }
    case ActionTypes.POST_USER_FEEDBACK: {
      const newState = { ...state };
      newState[action.assignmentId].custom.push({ message: action.feedback, messageId: action.messageId, userId: action.userId });
      return newState;
    }
    case ActionTypes.DELETE_USER_FEEDBACK: {
      const newState = { ...state };
      newState[action.assignmentId].custom.splice(action.arrayId, 1);
      return newState;
    }
    default:
      return state;
  }
}

