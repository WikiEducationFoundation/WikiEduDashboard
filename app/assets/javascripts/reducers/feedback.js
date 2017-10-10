import {
  RECEIVE_ARTICLE_FEEDBACK,
  POST_USER_FEEDBACK,
  DELETE_USER_FEEDBACK
} from "../constants";

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
      newState[action.assignmentId].custom.push({ message: action.feedback, messageId: action.messageId, userId: action.userId });
      return newState;
    }
    case DELETE_USER_FEEDBACK: {
      const newState = { ...state };
      newState[action.assignmentId].custom.splice(action.arrayId, 1);
      return newState;
    }
    default:
      return state;
  }
}
