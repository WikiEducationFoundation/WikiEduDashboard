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

const grantAdminPromise = (username, newStatus) => {
  return new Promise((accept, reject) => {
    return $.ajax({
      type: 'POST',
      url: `users/update_admin`,
      data: { username: username, new_status: newStatus },
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

export const updateAdminStatus = (username, newStatus) => dispatch => {
  // update a user's admin status
  // username: user's username
  // newStatus (bool): if user should be an admin. If false, user is made an instructor
  dispatch({
    type: SUBMITTING_NEW_ADMIN,
    data: {
      submitting: true,
    },
  });

  grantAdminPromise(username, newStatus)
    .then(() => {
      dispatch({
        type: SUBMITTING_NEW_ADMIN,
        data: {
        submitting: false
        },
      });
      const status = newStatus ? 'upgraded to' : 'downgraded from';
      dispatch(addNotification({
        type: 'success',
        message: `${username} was ${status} administrator.`,
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
