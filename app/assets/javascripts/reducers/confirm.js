import { CONFIRMATION_INITIATED, ACTION_CONFIRMED, ACTION_CANCELLED } from '../constants';

const initialState = {
  explanation: null,
  confirmationActive: false,
  confirmMessage: null,
  onConfirm: null,
  showInput: false,
  warningMessage: null
};

export default function ui(state = initialState, action) {
  switch (action.type) {
    case CONFIRMATION_INITIATED:
      return {
        explanation: action.explanation,
        confirmationActive: true,
        confirmMessage: action.confirmMessage,
        onConfirm: action.onConfirm,
        showInput: action.showInput,
        warningMessage: action.warningMessage
      };
    case ACTION_CONFIRMED:
    case ACTION_CANCELLED:
      return initialState;
    default:
      return state;
  }
}
