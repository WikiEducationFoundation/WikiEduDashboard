import { extend } from 'lodash-es';
import {
  RECEIVE_TRAINING_MODULE, MENU_TOGGLE, REVIEW_ANSWER,
  SET_CURRENT_SLIDE, RECEIVE_ALL_TRAINING_MODULES,
  EXERCISE_COMPLETION_UPDATE, SLIDE_COMPLETED, API_FAIL,
  UPDATE_WIKI_EDIT_ASSIGNMENT_STATUS
} from '../constants';
import request from '../utils/request';
import logErrorMessage from '../utils/log_error_message';
import { stringify } from 'query-string';
import { getLastWikiEdit } from '../utils/wiki_utils';

const fetchAllTrainingModulesPromise = async () => {
  const response = await request('/training_modules.json');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const fetchTrainingModulePromise = async (opts) => {
  const response = await request(`/training_module.json?module_id=${opts.module_id}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const setSlideCompletedPromise = async (opts) => {
  const params = {
    module_id: opts.module_id,
    user_id: opts.user_id,
    slide_id: opts.slide_id
  };
  const response = await request(`/training_modules_users.json?${stringify(params)}`, {
    method: 'POST'
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const fetchAllTrainingModules = () => (dispatch) => {
  return fetchAllTrainingModulesPromise()
    .then(resp => dispatch({ type: RECEIVE_ALL_TRAINING_MODULES, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const fetchTrainingModule = (opts = {}) => (dispatch) => {
  return fetchTrainingModulePromise(opts)
    .then((resp) => {
      const valid = !!resp.training_module.slides.filter(o => o.slug === opts.slide_id).length;
      dispatch({ type: RECEIVE_TRAINING_MODULE, data: extend(resp, { slide: opts.slide_id, valid }) });

      if (valid && opts.user_id) {
        dispatch(setSlideCompleted(opts));
      }
    }).catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const setSlideCompleted = opts => (dispatch, getState) => {
  // No need to ping the server if the module is already complete.
  if (getState().training.completed) { return; }

  return setSlideCompletedPromise(opts)
    .then(resp => dispatch({ type: SLIDE_COMPLETED, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

const setExerciseModule = (complete = true) => (block_id, module_id) => (dispatch) => {
  return request('/training_modules_users/exercise.json', {
    body: JSON.stringify({ block_id, complete, module_id }),
    method: 'POST'
  }).then(resp => resp.json())
    .then(resp => dispatch({ type: EXERCISE_COMPLETION_UPDATE, data: resp }))
    .catch(resp => dispatch({ type: API_FAIL, data: resp }));
};

export const setExerciseModuleComplete = setExerciseModule();
export const setExerciseModuleIncomplete = setExerciseModule(false);

export const toggleMenuOpen = opts => (dispatch) => {
  return dispatch({
    type: MENU_TOGGLE,
    data: {
      currently: opts.currently
    }
  });
};

export const reviewAnswer = answer => (dispatch) => {
  return dispatch({
    type: REVIEW_ANSWER,
    data: {
      answer
    }
  });
};

export const setCurrentSlide = slideId => (dispatch) => {
  return dispatch({
    type: SET_CURRENT_SLIDE,
    data: {
      slide: slideId
    }
  });
};

export const refreshEditAssignmentStatus = opts => (dispatch) => {
  const { wikiEditAssignment, username } = opts;
  if (!wikiEditAssignment || !username) return;
  dispatch({
    type: UPDATE_WIKI_EDIT_ASSIGNMENT_STATUS,
    data: 1 // loading status
  });
  getLastWikiEdit(wikiEditAssignment, username).then((data) => {
    if (!data) {
      dispatch({
        type: UPDATE_WIKI_EDIT_ASSIGNMENT_STATUS,
        data: 0 // page not found, so PENDING status
      });
      return;
    }

    if (data.user && data.user === username) {
      dispatch({
        type: UPDATE_WIKI_EDIT_ASSIGNMENT_STATUS,
        data: 3 // COMPLETED
      });
    }
  }).catch(() => {
    dispatch({
      type: UPDATE_WIKI_EDIT_ASSIGNMENT_STATUS,
      data: 2 // ERROR
    });
  });
};
