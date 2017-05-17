import { TOGGLE_UI } from '../constants/action_types.js';

const initialState = { openKey: null };

export default function ui(state = initialState, action) {
  switch (action.type) {
    case TOGGLE_UI:
      if (action.key === state.openKey) {
        return { ...state, openKey: null };
      }
      return { ...state, openKey: action.key };
    default:
      return state;
  }
}
