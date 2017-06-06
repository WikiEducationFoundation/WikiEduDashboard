import {
  SET_NEW_ACCOUNT_EMAIL,
  SET_NEW_ACCOUNT_USERNAME,
  NEW_ACCOUNT_REQUEST_SUBMITTED,
  NEW_ACCOUNT_USERNAME_INVALID
} from '../constants/action_types.js';

const initialState = { username: '', email: '' };

export default function newAccount(state = initialState, action) {
  switch (action.type) {
    case SET_NEW_ACCOUNT_EMAIL:
      return { ...state, email: action.email };
    case SET_NEW_ACCOUNT_USERNAME:
      return { ...state, username: action.username };
    case NEW_ACCOUNT_REQUEST_SUBMITTED:
      return { ...state, error: undefined, checking: true };
    case NEW_ACCOUNT_USERNAME_INVALID:
      return { ...state, error: actions.error, checking: false };
    default:
      return state;
  }
}
