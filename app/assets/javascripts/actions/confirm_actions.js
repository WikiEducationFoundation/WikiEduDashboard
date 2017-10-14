import { CONFIRMATION_INITIATED,
  ACTION_CONFIRMED,
  ACTION_CANCELLED
} from '../constants/confirmation.js';

export const confirmationInitiated = () => ({
  type: CONFIRMATION_INITIATED,
  data: {}
});
export const actionConfirmed = () => ({
  type: ACTION_CONFIRMED,
  data: {}
});
export const actionCancelled = () => ({
  type: ACTION_CANCELLED,
  data: {}
});

