import deepFreeze from 'deep-freeze';
import newAccount from '../../app/assets/javascripts/reducers/new_account';
import {
  SET_NEW_ACCOUNT_EMAIL,
  SET_NEW_ACCOUNT_USERNAME,
  NEW_ACCOUNT_VALIDATING_USERNAME,
  NEW_ACCOUNT_USERNAME_VALID,
  NEW_ACCOUNT_USERNAME_INVALID,
  NEW_ACCOUNT_REQUEST_SUBMITTED
} from '../../app/assets/javascripts/constants';
import '../testHelper';

const initialState = {
  username: '',
  email: ''
};

describe('new_account reducer', () => {
  test('should return the initial state', () => {
    expect(newAccount(undefined, {})).toEqual(initialState);
  });

  test('should set email and emailValid to true for a valid email on SET_NEW_ACCOUNT_EMAIL', () => {
    deepFreeze(initialState);
    const action = { type: SET_NEW_ACCOUNT_EMAIL, email: 'user@example.com' };
    const newState = newAccount(initialState, action);
    expect(newState.email).toBe('user@example.com');
    expect(newState.emailValid).toBe(true);
  });

  test('should set emailValid to false for an invalid email on SET_NEW_ACCOUNT_EMAIL', () => {
    deepFreeze(initialState);
    const action = { type: SET_NEW_ACCOUNT_EMAIL, email: 'notanemail' };
    const newState = newAccount(initialState, action);
    expect(newState.email).toBe('notanemail');
    expect(newState.emailValid).toBe(false);
  });

  test('should set username and clear usernameValid on SET_NEW_ACCOUNT_USERNAME', () => {
    const validatedState = { ...initialState, username: 'old', usernameValid: true };
    deepFreeze(validatedState);
    const action = { type: SET_NEW_ACCOUNT_USERNAME, username: 'newuser' };
    const newState = newAccount(validatedState, action);
    expect(newState.username).toBe('newuser');
    expect(newState.usernameValid).toBeUndefined();
  });

  test('should set checking to true and clear error on NEW_ACCOUNT_VALIDATING_USERNAME', () => {
    const errorState = { ...initialState, error: 'some error' };
    deepFreeze(errorState);
    const action = { type: NEW_ACCOUNT_VALIDATING_USERNAME };
    const newState = newAccount(errorState, action);
    expect(newState.checking).toBe(true);
    expect(newState.error).toBeUndefined();
  });

  test('should set usernameValid to true and checking to false on NEW_ACCOUNT_USERNAME_VALID', () => {
    const checkingState = { ...initialState, checking: true };
    deepFreeze(checkingState);
    const action = { type: NEW_ACCOUNT_USERNAME_VALID };
    const newState = newAccount(checkingState, action);
    expect(newState.usernameValid).toBe(true);
    expect(newState.checking).toBe(false);
  });

  test('should set error and checking to false on NEW_ACCOUNT_USERNAME_INVALID', () => {
    const checkingState = { ...initialState, checking: true };
    deepFreeze(checkingState);
    const action = { type: NEW_ACCOUNT_USERNAME_INVALID, error: 'Username taken' };
    const newState = newAccount(checkingState, action);
    expect(newState.error).toBe('Username taken');
    expect(newState.checking).toBe(false);
  });

  test('should set submitted to true on NEW_ACCOUNT_REQUEST_SUBMITTED', () => {
    deepFreeze(initialState);
    const action = { type: NEW_ACCOUNT_REQUEST_SUBMITTED };
    const newState = newAccount(initialState, action);
    expect(newState.submitted).toBe(true);
  });

  test('should return the current state for unknown action types', () => {
    deepFreeze(initialState);
    const action = { type: 'UNKNOWN_ACTION' };
    const newState = newAccount(initialState, action);
    expect(newState).toEqual(initialState);
  });
});
