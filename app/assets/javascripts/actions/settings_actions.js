import { SET_ADMIN_USERS, SUBMITTING_NEW_ADMIN, REVOKING_ADMIN } from '../constants/settings';
import { API_FAIL } from '../constants/api';
import { addNotification } from '../actions/notification_actions';
import logErrorMessage from '../utils/log_error_message';

const fetchAdminUsersPromise = () => {
  return new Promise((accept, reject) => {
    return $.ajax({
      type: 'GET',
      url: 'settings/all_admins',
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

/*
  generate promise to either upgrade or demote admin
  username(string)
  upgrade(bool): if the user is being upgraded. If false, user is demoted.
*/
const grantAdminPromise = (username, upgrade) => {
  const url = `/settings/${upgrade ? 'upgrade' : 'downgrade'}_admin`;
  return new Promise((accept, reject) => {
    return $.ajax({
      type: 'POST',
      url: url,
      data: { user: { username: username } },
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

export function fetchAdminUsers() {
  return (dispatch) => {
    return fetchAdminUsersPromise()
      .then((resp) => {
        dispatch({
          type: SET_ADMIN_USERS,
          data: resp,
        });
      })
      .catch((response) => {
        dispatch({ type: API_FAIL, data: response });
      });
  };
}

export const upgradeAdmin = username => (dispatch) => {
  // grant a user admin status
  // username: user's username
    dispatch({
      type: SUBMITTING_NEW_ADMIN,
      data: {
        submitting: true,
      },
    });

    return grantAdminPromise(username, true)
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
          .catch(response => (dispatch({ type: API_FAIL, data: response })));
      }).catch((response) => {
        dispatch({
          type: SUBMITTING_NEW_ADMIN,
          data: {
          submitting: false
          },
        });

        dispatch(addNotification({
          type: 'error',
          message: response.responseJSON.message,
          closable: true
          })
        );
      });
};

export const downgradeAdmin = username => (dispatch) => {
  // remove a user's admin status
  // username: user's username
  dispatch({
    type: REVOKING_ADMIN,
    data: {
      revoking: {
        status: true,
        username: username,
      },
    },
  });

  return grantAdminPromise(username, false)
    .then(() => {
      dispatch(addNotification({
        type: 'success',
        message: `${username} was removed as an administrator.`,
        closable: true
      })
      );

      fetchAdminUsersPromise()
        .then((resp) => {
          dispatch({
            type: SET_ADMIN_USERS,
            data: resp,
          });

          dispatch({
            type: REVOKING_ADMIN,
            data: {
              revoking: {
                status: false,
                username: username,
              },
            },
          });
        }).catch(
          response => (dispatch({ type: API_FAIL, data: response }))
        );
    }).catch((response) => {
      dispatch({
        type: SUBMITTING_NEW_ADMIN,
        data: {
          submitting: false
        },
      });

      dispatch(addNotification({
        type: 'error',
        message: response.responseJSON.message,
        closable: true
      })
      );
    });
};
