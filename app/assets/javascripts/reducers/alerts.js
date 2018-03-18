import { RECEIVE_ALERTS, SORT_ALERTS, FILTER_ALERTS } from "../constants";

const initialState = {
  sortKey: null,
  selectedFilters: [
    'ArticlesForDeletionAlert',
    'DiscretionarySanctionsEditAlert',
  ],
};

export default function alerts(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ALERTS: {
      const newState = {
        ...state,
        alerts: action.data.alerts,
        selectedAlerts: action.data.alerts,
        };
      if (newState.selectedFilters) {
          newState.selectedAlerts = newState.alerts.filter(alert => newState.selectedFilters.indexOf(alert.type) !== -1);
      }
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
    case FILTER_ALERTS: {
      const newState = { ...state };
      newState.selectedFilters = action.selectedFilters;
      if (newState.selectedFilters) {
        newState.selectedAlerts = newState.alerts.filter(alert => newState.selectedFilters.indexOf(alert.type) !== -1);
      }
      else {
        newState.selectedAlerts = newState.alerts;
      }
      return newState;
    }
    default:
      return state;
  }
}
