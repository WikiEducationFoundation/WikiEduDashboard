import { ADD_NOTIFICATION, API_FAIL, UPDATE_COURSE, RECEIVE_COURSE, PERSISTED_COURSE } from '../constants';
import API from '../utils/api.js';

export const fetchCourse = (courseId) => (dispatch) => {
  return API.fetch(courseId, 'course')
    .then(data => dispatch({ type: RECEIVE_COURSE, data }))
    .catch(data => ({ type: API_FAIL, data }));
};


export const updateCourse = course => ({ type: UPDATE_COURSE, course });

export const resetCourse = () => (dispatch, getState) => {
  const persistedCourse = getState().persistedCourse;
  dispatch({ type: UPDATE_COURSE, course: { ...persistedCourse } });
};

export const persistCourse = (courseId = null) => (dispatch, getState) => {
  const course = getState().course;
  return API.saveCourse({ course }, courseId)
    .then(resp => dispatch({ type: PERSISTED_COURSE, data: resp }))
    .catch(data => ({ type: API_FAIL, data }));
};

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
      .catch(data => dispatch({ type: API_FAIL, data }));
  };
}

