import {
  RECEIVE_ARTICLE_FEEDBACK,
  POST_USER_FEEDBACK,
  DELETE_USER_FEEDBACK
} from '../constants';

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
      const assignmentId = action.assignmentId;
      newState[assignmentId] = { ...newState[assignmentId],
      custom: [
      ...(newState[assignmentId]?.custom || []),
      { message: action.feedback, messageId: action.messageId, userId: action.userId }
    ]
  };
      return newState;
    }
    case DELETE_USER_FEEDBACK: {
      const newState = { ...state };
      const assignmentId = action.assignmentId;
      newState[assignmentId] = {
        ...newState[assignmentId],
        custom: newState[assignmentId]?.custom.filter((item, index) => index !== action.arrayId)
      };
      return newState;
    }
    default:
      return state;
  }
}
