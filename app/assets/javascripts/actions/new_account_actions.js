import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import API from '../utils/api.js';
import request from '../utils/request';

const _checkAvailability = async (newAccount) => {
  const response = await request(`https://meta.wikimedia.org/w/api.php?action=query&list=users&ususers=${newAccount.username}&usprop=cancreate&format=json&origin=*`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
};

export const setNewAccountUsername = (_, username) => ({
  type: types.SET_NEW_ACCOUNT_USERNAME, username
});

export const setNewAccountEmail = (_, email) => ({
  type: types.SET_NEW_ACCOUNT_EMAIL, email
});

export const checkAvailability = newAccount => (dispatch) => {
  dispatch({ type: types.NEW_ACCOUNT_VALIDATING_USERNAME });
  return (
    _checkAvailability(newAccount)
      .then((resp) => {
        if (resp.cancreate === '') {
          return dispatch({ type: types.NEW_ACCOUNT_USERNAME_VALID });
        }
        return dispatch({ type: types.NEW_ACCOUNT_USERNAME_INVALID, error: parseCancreateResponse(resp) });
      }).catch(response => (dispatch({ type: types.API_FAIL, data: response })))
  );
};


const parseCancreateResponse = (response) => {
  if (response.cancreateerror) {
    const error = response.cancreateerror[0];
    if (error.code === '$1') {
      return error.params[0];
    } else if (error.code === 'userexists') {
      return I18n.t('courses.new_account_username_taken');
    } else if (error.code === 'invaliduser') {
      return I18n.t('courses.new_account_username_invalid');
    }
    return error.code;
  }
  if (response.missing !== '') {
    return I18n.t('courses.new_account_username_taken');
  }
  return 'unknown error';
};

export function requestAccount(passcode, course, newAccount, createAccountNow = false) {
  return function (dispatch) {
    const courseSlug = course.slug;
    const { username, email } = newAccount;

    return API.requestNewAccount(passcode, courseSlug, username, email, createAccountNow)
      .then((data) => {
        dispatch({ type: types.NEW_ACCOUNT_REQUEST_SUBMITTED });
        dispatch({ type: types.ADD_NOTIFICATION, notification: { type: 'success', message: data.message, closable: true } });
      })
      .catch(data => (dispatch({ type: types.API_FAIL, data })));
  };
}

export function enableAccountRequests(course) {
  return function (dispatch) {
    const courseSlug = course.slug;

    return API.enableAccountRequests(courseSlug)
      .then(() => (dispatch({ type: types.ACCOUNT_REQUESTS_ENABLED })))
      .catch(data => (dispatch({ type: types.API_FAIL, data })));
  };
}
