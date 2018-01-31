import {
  SET_NEW_ACCOUNT_EMAIL,
  SET_NEW_ACCOUNT_USERNAME,
  NEW_ACCOUNT_VALIDATING_USERNAME,
  NEW_ACCOUNT_USERNAME_VALID,
  NEW_ACCOUNT_USERNAME_INVALID,
  NEW_ACCOUNT_REQUEST_SUBMITTED
} from '../constants/new_accounts.js';

const initialState = { username: '', email: '' };

const emailIsValid = (email) => {
  return /.+@.+/.test(email);
};

export default function newAccount(state = initialState, action) {
  switch (action.type) {
    case SET_NEW_ACCOUNT_EMAIL:
      return { ...state, email: action.email, emailValid: emailIsValid(action.email) };
    case SET_NEW_ACCOUNT_USERNAME:
      return { ...state, username: action.username, usernameValid: undefined };
    case NEW_ACCOUNT_VALIDATING_USERNAME:
      return { ...state, error: undefined, checking: true };
    case NEW_ACCOUNT_USERNAME_VALID:
      return { ...state, usernameValid: true, checking: false };
    case NEW_ACCOUNT_USERNAME_INVALID:
      return { ...state, error: action.error, checking: false };
    case NEW_ACCOUNT_REQUEST_SUBMITTED:
      return { ...state, submitted: true };
    default:
      return state;
  }
}
