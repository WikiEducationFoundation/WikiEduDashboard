import _ from 'lodash';
import {
  RECEIVE_TRAINING_MODULE, MENU_TOGGLE, SET_SELECTED_ANSWER,
  SET_CURRENT_SLIDE, RECEIVE_ALL_TRAINING_MODULES,
  SLIDE_COMPLETED, API_FAIL
} from '../constants';

const fetchAllTrainingModulesPromise = () => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: '/training_modules.json',
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    })
  );
};

const fetchTrainingModulePromise = (opts) => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: `/training_module.json?module_id=${opts.module_id}`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    })
  );
};

const setSlideCompletedPromise = (opts) => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'POST',
      url: `/training_modules_users.json?\
module_id=${opts.module_id}&\
user_id=${opts.user_id}&\
slide_id=${opts.slide_id}`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    })
  );
};


export const fetchAllTrainingModules = () => (dispatch) => {
  return fetchAllTrainingModulesPromise()
    .then(resp => dispatch({ type: RECEIVE_ALL_TRAINING_MODULES, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const fetchTrainingModule = (opts = {}) => (dispatch) => {
  return fetchTrainingModulePromise(opts)
    .then(resp => dispatch({ type: RECEIVE_TRAINING_MODULE, data: _.extend(resp, { slide: opts.current_slide_id }) }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const setSlideCompleted = (opts) => (dispatch) => {
  return setSlideCompletedPromise(opts)
    .then(resp => dispatch({ type: SLIDE_COMPLETED, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const toggleMenuOpen = (opts) => (dispatch) => {
  return dispatch({
    type: MENU_TOGGLE,
    data: {
      currently: opts.currently
    }
  });
};

export const setSelectedAnswer = (answer) => (dispatch) => {
  return dispatch({
    type: SET_SELECTED_ANSWER,
    data: {
      answer
    }
  });
};

export const setCurrentSlide = (slideId) => (dispatch) => {
  return dispatch({
    type: SET_CURRENT_SLIDE,
    data: {
      slide: slideId
    }
  });
};
