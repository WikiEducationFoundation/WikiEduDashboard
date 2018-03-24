import { INITIALIZE, SET_VALID, SET_INVALID, CHECK_SERVER, API_FAIL } from "../constants";
import API from '../utils/api.js';

export const initialize = (key, message) => {
  return {
    type: INITIALIZE,
    data: {
      key: key,
      message: message
    }
  };
};

export const setValid = (key) => {
  return {
    type: SET_VALID,
    data: {
      key: key,
    }
  };
};

export const setInvalid = (key, message) => {
  return {
    type: SET_INVALID,
    data: {
      key: key,
      message: message,
    }
  };
};

export const checkServer = (key, message) => {
  return {
    type: CHECK_SERVER,
    data: {
      key: key,
      message: message
    }
  };
};

export const checkCourse = (key, courseId) => dispatch => {
  return API.fetch(courseId, 'check')
    .then(resp => dispatch({
        type: CHECK_SERVER,
        data: {
          key: key,
          message: resp.course_exists ? I18n.t('courses.creator.already_exists') : null
        }
      }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};
