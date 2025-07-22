import * as types from '../constants';

// UI reducer
export const toggleUI = key => ({ type: types.TOGGLE_UI, key });
export const resetUI = key => ({ type: types.RESET_UI, key });

// Confirm reducer
export const initiateConfirm = () => ({ type: types.CONFIRMATION_INITIATED });
export const confirmAction = () => ({ type: types.ACTION_CONFIRMED });
export const cancelAction = () => ({ type: types.ACTION_CANCELLED });
