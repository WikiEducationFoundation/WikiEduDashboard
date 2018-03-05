import { RECEIVE_ALERTS } from "../constants";

const initialState = {};

export default function alerts(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ALERTS: {
      const newState = {
        ...state,
        alerts: action.data.alerts
        };
      return newState;
    }
    default:
      return state;
  }
}
