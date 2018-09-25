import { RECEIVE_TRAINING_STATUS } from '../constants';

const initialState = {};

export default function trainingStatus(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_TRAINING_STATUS: {
      const newState = { ...state };
      newState[action.userId] = action.data.course.training_modules;
      return newState;
    }
    default:
      return state;
  }
}
