import { CONFIRMATION_INITIATED, ACTION_CONFIRMED, ACTION_CANCELLED } from '../constants';

const initialState = {
  confirmationActive: false,
  confirmMessage: null,
  onConfirm: null,
  showInput: false,
  explanation: null
};

export default function ui(state = initialState, action) {
  switch (action.type) {
    case CONFIRMATION_INITIATED:
      return {
        confirmationActive: true,
        confirmMessage: action.confirmMessage,
        onConfirm: action.onConfirm,
        showInput: action.showInput,
        explanation: action.explanation
      };
    case ACTION_CONFIRMED:
    case ACTION_CANCELLED:
      return initialState;
    default:
      return state;
  }
}
