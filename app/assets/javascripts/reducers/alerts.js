import { RECEIVE_ALERTS, SORT_ALERTS } from "../constants";

const initialState = {
  sortKey: null
};

export default function alerts(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ALERTS: {
      const newState = {
        ...state,
        alerts: action.data.alerts
        };
      return newState;
    }
    case SORT_ALERTS: {
      const newState = { ...state };
      if (action.key === state.sortKey) {
        newState.alerts = _.sortBy(state.alerts, action.key).reverse();
        newState.sortKey = null;
      } else {
        newState.alerts = _.sortBy(state.alerts, action.key);
        newState.sortKey = action.key;
      }
      return newState;
    }
    default:
      return state;
  }
}
