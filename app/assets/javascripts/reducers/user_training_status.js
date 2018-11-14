import { RECEIVE_USER_TRAINING_STATUS } from '../constants';

const initialState = [];

export default function userTrainingStatus(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_TRAINING_STATUS: {
      return action.data.user.training_modules;
    }
    default:
      return state;
  }
}
