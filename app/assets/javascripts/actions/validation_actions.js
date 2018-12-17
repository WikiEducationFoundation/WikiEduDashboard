import API from '../utils/api.js';
import { ADD_VALIDATION, SET_VALID, SET_INVALID, COURSE_SLUG_EXISTS, COURSE_SLUG_OKAY, ACTIVATE_VALIDATIONS, API_FAIL, RESET_VALIDATIONS } from '../constants';

export const addValidation = (key, message) => (dispatch) => {
  dispatch({ type: ADD_VALIDATION, key, message });
};

export const setValid = (key, quiet = false) => (dispatch) => {
  dispatch({ type: SET_VALID, key, quiet });
};

export const setInvalid = (key, message, quiet = false) => (dispatch) => {
  dispatch({ type: SET_INVALID, key, message, quiet });
};

export const checkCourseSlug = slug => (dispatch) => {
  // Ensure course name is unique
  return API.fetch(slug, 'check')
    .then((resp) => {
      if (resp.course_exists) {
        return dispatch({ type: COURSE_SLUG_EXISTS, message: I18n.t('courses.creator.already_exists') });
      }
      return dispatch({ type: COURSE_SLUG_OKAY });
    })
    .catch(data => ({ type: API_FAIL, data }));
};

export const activateValidations = () => dispatch => dispatch({ type: ACTIVATE_VALIDATIONS });

export const resetValidations = () => dispatch => dispatch({ type: RESET_VALIDATIONS });
