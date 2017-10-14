import { TOGGLE_UI, RESET_UI } from '../constants';

const initialState = { openKey: null };

export default function ui(state = initialState, action) {
  switch (action.type) {
    case TOGGLE_UI:
      if (action.key === state.openKey) {
        return { ...state, openKey: null };
      }
      return { ...state, openKey: action.key };
    case RESET_UI:
      return { ...state, openKey: null };
    default:
      return state;
  }
}
