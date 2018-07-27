import { ADD_NOTIFICATION, API_FAIL, UPDATE_COURSE, RECEIVE_COURSE, PERSISTED_COURSE } from '../constants';
import API from '../utils/api.js';
import CourseUtils from '../utils/course_utils';

export const fetchCourse = (courseSlug) => (dispatch) => {
  return API.fetch(courseSlug, 'course')
    .then(data => dispatch({ type: RECEIVE_COURSE, data }))
    .catch(data => ({ type: API_FAIL, data }));
};

export const updateCourse = course => ({ type: UPDATE_COURSE, course });

export const resetCourse = () => (dispatch, getState) => {
  const persistedCourse = getState().persistedCourse;
  dispatch({ type: UPDATE_COURSE, course: { ...persistedCourse } });
};

export const nameHasChanged = () => (_dispatch, getState) => {
  const { course, persistedCourse } = getState();
  if (course.title !== persistedCourse.title) { return true; }
  if (course.term !== persistedCourse.term) { return true; }
  if (course.school !== persistedCourse.school) { return true; }
  return false;
};

const redirectCourse = newSlug => {
  if (!newSlug) { return; }
  window.location = `/courses/${newSlug}`;
};

export const persistCourse = (courseSlug = null, redirect = false) => (dispatch, getState) => {
  let course = getState().course;

  let newSlug;
  if (redirect) {
    course = CourseUtils.cleanupCourseSlugComponents(course);
    newSlug = CourseUtils.generateTempId(course);
    course.slug = newSlug;
  }

  return API.saveCourse({ course }, courseSlug)
    .then(resp => dispatch({ type: PERSISTED_COURSE, data: resp }))
    .then(() => redirectCourse(newSlug))
    .catch(data => ({ type: API_FAIL, data }));
};

const needsUpdatePromise = (courseSlug) => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: `/courses/${courseSlug}/needs_update.json`,
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

export function needsUpdate(courseSlug) {
  return function (dispatch) {
    return needsUpdatePromise(courseSlug)
      .then(resp => dispatch({ type: ADD_NOTIFICATION, notification: needsUpdateNotification(resp) }))
      .catch(data => dispatch({ type: API_FAIL, data }));
  };
}
