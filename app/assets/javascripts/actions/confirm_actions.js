import { CONFIRMATION_INITIATED, ACTION_CONFIRMED, ACTION_CANCELLED } from '../constants';

export const initiateConfirm = ({
  confirmMessage, onConfirm, showInput, explanation, warningMessage
}) => ({
  type: CONFIRMATION_INITIATED,
  confirmMessage,
  onConfirm,
  showInput,
  explanation,
  warningMessage
});

export const confirmAction = () => ({ type: ACTION_CONFIRMED });
export const cancelAction = () => ({ type: ACTION_CANCELLED });
