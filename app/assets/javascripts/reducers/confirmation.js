import { CONFIRMATION_INITIATED,
  ACTION_CONFIRMED,
  ACTION_CANCELLED
} from '../constants/action_types.js';

const initialState = {_confirmationActive : false};

export default function ConfirmationStore(state = initialState, action) {
  switch (action.type) {
    case CONFIRMATION_INITIATED: {
      return { ...state, _confirmationActive: true };
    }
    case ACTION_CONFIRMED: {
      return { ...state, _confirmationActive: false };
    }
    case ACTION_CANCELLED: {
      return { ...state, _confirmationActive: false };
    }
    default:
      return state;
  }
}



