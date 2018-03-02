import {
  RECEIVE_ALERTS
} from '../constants/alert.js';

const initialState = {
  alerts: []
};

export default function alerts(state = initialState, action) {
  switch (action.types) {
    case RECEIVE_ALERTS: {
      const newState = {
        ...state,
        alerts: data.alerts
        };
      return newState;
      }
    default:
      return state;
  }
}
