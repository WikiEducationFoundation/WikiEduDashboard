import { TOGGLE_SCOPING_METHOD } from '../constants/scoping_methods';

const initialState = {
  selected: [],
};

export default function course(state = initialState, action) {
  switch (action.type) {
    case TOGGLE_SCOPING_METHOD: {
      if (state.selected.includes(action.method)) {
        return {
          ...state,
          selected: state.selected.filter(method => method !== action.method).sort(),
        };
      }
      return {
        ...state,
        selected: [...state.selected, action.method].sort(),
      };
    }
    default:
      return state;
  }
}
