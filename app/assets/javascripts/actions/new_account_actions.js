import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import API from '../utils/api.js';
import request from '../utils/request';

const _checkAvailability = async (newAccount) => {
  const response = await request(`https://meta.wikimedia.org/w/api.php?action=query&list=users&ususers=${newAccount.username}&usprop=cancreate&format=json&origin=*`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const setNewAccountUsername = (_, username) => ({
  type: types.SET_NEW_ACCOUNT_USERNAME, username
});

export const setNewAccountEmail = (_, email) => ({
  type: types.SET_NEW_ACCOUNT_EMAIL, email
});

const canCreateAccount = (response) => {
  const user = response.query.users[0];
  if (user.cancreate === '') {
    return true;
  }
  return false;
};

const parseCanCreateResponse = (response) => {
  const user = response.query.users[0];
  if (user.cancreateerror) {
    const error = user.cancreateerror[0];
    if (error.code === '_1') {
      return error.params[0];
    } else if (error.code === 'userexists') {
      return I18n.t('courses.new_account_username_taken');
    } else if (error.code === 'invaliduser') {
      return I18n.t('courses.new_account_username_invalid');
    }
    return error.code;
  }
  if (user.missing !== '') {
    return I18n.t('courses.new_account_username_taken');
  }
  return 'unknown error';
};

export const checkAvailability = newAccount => (dispatch) => {
  dispatch({ type: types.NEW_ACCOUNT_VALIDATING_USERNAME });
  return (
    _checkAvailability(newAccount)
      .then((resp) => {
        // As of 2022-03-17, responses look like this:
        // Valid: {"batchcomplete":"","query":{"users":[{"name":"Something Something New Editor","missing":"","cancreate":""}]}}
        // Taken: {"batchcomplete":"","query":{"users":[{userid: 28076, name: 'Ragesoss'}]}}
        // Too similar: {"batchcomplete":"","query":{"users":[{"name":"Rages0ss","missing":"","cancreateerror":[{"message":"$1","params":["The username &quot;Rages0ss&quot; is too similar to the following username:<ul><li>Ragesoss</li></ul>Please choose another username."],"code":"_1","type":"error"}]}]}}
        if (canCreateAccount(resp)) {
          return dispatch({ type: types.NEW_ACCOUNT_USERNAME_VALID });
        }
        return dispatch({ type: types.NEW_ACCOUNT_USERNAME_INVALID, error: parseCanCreateResponse(resp) });
      }).catch(response => (dispatch({ type: types.API_FAIL, data: response })))
  );
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
