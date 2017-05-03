import { createStore } from 'redux';

// reducer
const uiReducer = (state = { openKey: null }, action) => {
  switch (action.type) {
    case 'OPEN_KEY':
      if (action.data.key === state.openKey) {
        return Object.assign({}, state, { openKey: null });
      }
      return Object.assign({}, state, { openKey: action.data.key });
    default:
      return state;
  }
};

// store
const ReduxStore = createStore(uiReducer);

export default ReduxStore;
