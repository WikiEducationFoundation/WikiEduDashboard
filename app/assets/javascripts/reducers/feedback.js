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
// The feedback state typically looks like this:
// {
//    assignmentId: {
//        custom: [
//            { message: 'Feedback message', messageId: '123', userId: '456' },
//            { message: 'Another feedback message', messageId: '789', userId: '101' },
//            ...
//        ],
//        ...
//    },
//    ...
// }

// Update the state with the new feedback message
      newState[assignmentId] = {
      ...newState[assignmentId],
      custom: [
        ...(newState[assignmentId]?.custom || []),
        { message: action.feedback, messageId: action.messageId, userId: action.userId }
    ]
  };// Using the spread operator to maintain the previous state
    // and then adding the new custom message
      return newState;
    }
    case DELETE_USER_FEEDBACK: {
      const newState = { ...state };
      const assignmentId = action.assignmentId;
      newState[assignmentId] = {
        ...newState[assignmentId],
        custom: newState[assignmentId]?.custom.filter((item, index) => index !== action.arrayId)
      };// The use of filter ensures that the original array remains unchanged,
        // and only the filtered array is used to update the state.
      return newState;
    }
    default:
      return state;
  }
}
