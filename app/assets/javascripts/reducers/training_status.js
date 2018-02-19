import {
  RECEIVE_TRAINING_STATUS,
  SORT_TRAINING_STATUS
} from '../constants/training_status.js';

const initialState = {
  training_status: [],
  isLoaded: false
};

export default function trainingStatus(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_TRAINING_STATUS:
      return {
        training_status: action.payload.data.training_status,
        isLoaded: true
      };
    case SORT_TRAINING_STATUS:
      return {
        training_status: action.payload.data.training_status,
        isLoaded: true
      };
    default:
      return state;
  }
}
