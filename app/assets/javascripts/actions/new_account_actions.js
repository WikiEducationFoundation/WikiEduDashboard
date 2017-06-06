import * as types from '../constants/action_types.js';
// import ApiFailAction from './api_fail_action.js';
// import API from '../utils/api.js';

export const setNewAccountUsername = (_, username) => ({
  type: types.SET_NEW_ACCOUNT_USERNAME, username
});

export const setNewAccountEmail = (_, email) => ({
  type: types.SET_NEW_ACCOUNT_EMAIL, email
});

export function requestAccount(passcode) {
  return function (dispatch, getState) {
    dispatch({ type: types.NEW_ACCOUNT_REQUEST_SUBMITTED });
    const state = getState().newAccount;
    const newAccount = { username: state.username, email: state.email };
    // TODO: validate email before pinging meta

    // validate username then submit to dashboard server
    $.ajax({
      dataType: 'jsonp',
      url: `https://meta.wikimedia.org/w/api.php?action=query&list=users&ususers=${newAccount.username}&usprop=cancreate&format=json`,
      success: (data) => {
        const result = data.query.users[0];
        if (result.cancreate === '') {
          requestValidAccount(dispatch, newAccount, passcode);
        } else if (result.cancreateerror) {
          dispatch({ type: types.NEW_ACCOUNT_USERNAME_INVALID, error: result.cancreateerror });
        }
      }
    }).fail(/* handle API failure */);
  };
}

const requestValidAccount = (dispatch, newAccount, passcode) => {
  // TODO: submit valid account name and passcode to dashboard
  console.log(newAccount)
  console.log(passcode)
}
