import _ from 'lodash';
import {
  RECEIVE_TRAINING_MODULE, MENU_TOGGLE, SET_SELECTED_ANSWER,
  SET_CURRENT_SLIDE, RECEIVE_ALL_TRAINING_MODULES,
  SLIDE_COMPLETED, API_FAIL
} from '../constants';

import API from '../utils/api.js';

export const fetchAllTrainingModules = () => (dispatch) => {
  return API.fetchAllTrainingModules()
    .then(resp => dispatch({ type: RECEIVE_ALL_TRAINING_MODULES, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const fetchTrainingModule = (opts = {}) => (dispatch) => {
  return API.fetchTrainingModule(opts)
    .then(resp => dispatch({ type: RECEIVE_TRAINING_MODULE, data: _.extend(resp, { slide: opts.current_slide_id }) }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const setSlideCompleted = (opts) => (dispatch) => {
  return API.setSlideCompleted(opts)
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
