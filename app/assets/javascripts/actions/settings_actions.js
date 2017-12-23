import { SET_ADMIN_USERS, SUBMITTING_NEW_ADMIN } from '../constants/settings';
import { API_FAIL } from '../constants/api';
import { addNotification } from '../actions/notification_actions';
import logErrorMessage from '../utils/log_error_message';

const fetchAdminUsersPromise = () => {
  return new Promise((accept, reject) => {
    return $.ajax({
      type: 'GET',
      url: `users/all_admins`,
      success(data) {
        return accept(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return reject(obj);
    });
  });
};

const grantAdminPromise = (username) => {
  return new Promise((accept, reject) => {
    return $.ajax({
      type: 'POST',
      url: '/users/upgrade_admin',
      data: { user: { username: username } },
      success(data) {
        return accept(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return reject(obj);
    });
  })
}

export const fetchAdminUsers = () => dispatch => {
  fetchAdminUsersPromise()
    .then(resp =>
      dispatch({
        type: SET_ADMIN_USERS,
        data: resp,
      }))
    .catch(response => (dispatch({ type: API_FAIL, data: response })))
};

export const upgradeAdmin = (username) => dispatch => {
  // update a user's admin status
  // username: user's username
  // newStatus (bool): if user should be an admin. If false, user is made an instructor
  dispatch({
    type: SUBMITTING_NEW_ADMIN,
    data: {
      submitting: true,
    },
  });

  grantAdminPromise(username)
    .then(() => {
      dispatch({
        type: SUBMITTING_NEW_ADMIN,
        data: {
        submitting: false
        },
      });
      dispatch(addNotification({
        type: 'success',
        message: `${username} was upgraded to administrator.`,
        closable: true
        })
      );

      fetchAdminUsersPromise()
        .then(resp =>
          dispatch({
            type: SET_ADMIN_USERS,
            data: resp,
          }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))

    }).catch((response) => {
      console.log(error)
      dispatch(addNotification({
        type: 'error',
        message: `error!`,
        closable: true
        })
      );
    });
};
