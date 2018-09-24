import { RECEIVE_TRAINING_STATUS, RECEIVE_USER_TRAINING_STATUS } from '../constants';


const initialState = {
  user: []
};

export default function trainingStatus(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_TRAINING_STATUS: {
      const newState = { ...state };
      newState[action.userId] = action.data.course.training_modules;
      return newState;
    }
    case RECEIVE_USER_TRAINING_STATUS: {
      const newState = { ...state };
      newState.user = action.data.course.training_modules;
      return newState;
    }
    default:
      return state;
  }
}
