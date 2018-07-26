import { ADD_NOTIFICATION, API_FAIL, UPDATE_COURSE } from '../constants';

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
      .then(resp => dispatch({ type: ADD_NOTIFICATION, notification: needsUpdateNotification(resp) }))
      .catch(resp => dispatch({ type: API_FAIL, data: resp }));
  };
}
export const updateCourse = course => ({ type: UPDATE_COURSE, course });
