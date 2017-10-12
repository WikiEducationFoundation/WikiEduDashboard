import * as types from '../constants';

export const toggleUI = key => ({ type: types.TOGGLE_UI, key });
export const resetUI = key => ({ type: types.RESET_UI, key });
