import * as types from '../constants';

const needsUpdatePromise = (courseId) => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/needs_update.json`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      rej(obj);
    })
  );
};

const needsUpdateNotification = response => {
  return {
    message: response.result,
    closable: true,
    type: 'success'
  };
};

export function needsUpdate(courseId) {
  return function (dispatch) {
    return needsUpdatePromise(courseId)
      .then(resp => dispatch({ type: types.ADD_NOTIFICATION, notification: needsUpdateNotification(resp) }))
      .catch(resp => dispatch({ type: types.API_FAIL, data: resp }));
  };
}
