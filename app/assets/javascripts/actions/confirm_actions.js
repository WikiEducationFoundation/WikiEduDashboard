import { CONFIRMATION_INITIATED, ACTION_CONFIRMED, ACTION_CANCELLED } from "../constants";

export const initiateConfirm = (confirmMessage, onConfirm, showInput, explanation) => ({
  type: CONFIRMATION_INITIATED,
  confirmMessage,
  onConfirm,
  showInput,
  explanation
});

export const confirmAction = () => ({ type: ACTION_CONFIRMED });
export const cancelAction = () => ({ type: ACTION_CANCELLED });
