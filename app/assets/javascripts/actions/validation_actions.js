import McFly from 'mcfly';
import API from '../utils/api.js';
import { ADD_VALIDATION, SET_VALID, SET_INVALID, COURSE_SLUG_EXISTS, COURSE_SLUG_OKAY } from '../constants';

const Flux = new McFly();

export const addValidation = (key, message) => (dispatch) => {
  dispatch({ type: ADD_VALIDATION, key, message });
  ValidationActions.initialize(key, message);
};

export const setValid = (key, quiet = false) => (dispatch) => {
  dispatch({ type: SET_VALID, key, quiet });
  ValidationActions.setValid(key, quiet);
};

export const setInvalid = (key, message, quiet = false) => (dispatch) => {
  dispatch({ type: SET_INVALID, key, message, quiet });
  ValidationActions.setInvalid(key, message, quiet);
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

const ValidationActions = Flux.createActions({
  // Workaround for dispatching a McFly action from a Redux action
  dispatchAction(action) {
    return action;
  },

  initialize(key, message) {
    return {
      actionType: 'INITIALIZE',
      data: {
        key,
        message
      }
    };
  },

  setValid(key, quiet = false) {
    return {
      actionType: 'SET_VALID',
      data: {
        key,
        quiet
      }
    };
  },

  setInvalid(key, message, quiet = false) {
    return {
      actionType: 'SET_INVALID',
      data: {
        key,
        message,
        quiet
      }
    };
  }
});

export default ValidationActions;
