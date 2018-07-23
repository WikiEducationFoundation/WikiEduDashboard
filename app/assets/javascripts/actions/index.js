import * as types from '../constants';

// Confirm reducer
export const initiateConfirm = () => ({ type: types.CONFIRMATION_INITIATED });
export const confirmAction = () => ({ type: types.ACTION_CONFIRMED });
export const cancelAction = () => ({ type: types.ACTION_CANCELLED });
