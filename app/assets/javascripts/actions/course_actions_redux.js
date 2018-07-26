import { ADD_NOTIFICATION, API_FAIL, UPDATE_COURSE, RECEIVE_COURSE } from '../constants';
import API from '../utils/api.js';
import CourseActions from './course_actions';

export const updateCourse = course => ({ type: UPDATE_COURSE, course });

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

export const fetchCourse = (courseId) => (dispatch) => {
  return API.fetch(courseId, 'course')
    .then(data => {
      dispatch({ type: RECEIVE_COURSE, data });
      return CourseActions.receiveCourse(data);
    })
    .catch(data => ({ type: API_FAIL, data }));
};
