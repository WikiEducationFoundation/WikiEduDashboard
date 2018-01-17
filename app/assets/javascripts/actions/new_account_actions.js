import * as types from '../constants/action_types.js';
import logErrorMessage from '../utils/log_error_message';
import API from '../utils/api.js';

export const setNewAccountUsername = (_, username) => ({
  type: types.SET_NEW_ACCOUNT_USERNAME, username
});

export const setNewAccountEmail = (_, email) => ({
  type: types.SET_NEW_ACCOUNT_EMAIL, email
});

export function checkAvailability(newAccount) {
  return function (dispatch) {
    dispatch({ type: types.NEW_ACCOUNT_VALIDATING_USERNAME });
    // validate username
    $.ajax({
      dataType: 'jsonp',
      url: `https://meta.wikimedia.org/w/api.php?action=query&list=users&ususers=${newAccount.username}&usprop=cancreate&format=json`,
      success: (data) => {
        const result = data.query.users[0];
        if (result.cancreate === '') {
          dispatch({ type: types.NEW_ACCOUNT_USERNAME_VALID });
        } else {
          dispatch({ type: types.NEW_ACCOUNT_USERNAME_INVALID, error: parseCancreateResponse(result) });
        }
      }
    }).fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  };
}

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

export function requestAccount(passcode, course, newAccount) {
  return function (dispatch) {
    const courseSlug = course.slug;
    const { username, email } = newAccount;
    return API.requestNewAccount(passcode, courseSlug, username, email)
      .then(() => (dispatch({ type: types.NEW_ACCOUNT_REQUEST_SUBMITTED })))
      .catch(data => ({ actionType: types.API_FAIL, data }));
  };
}
