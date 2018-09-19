
import * as types from '../constants';
import API from '../utils/api.js';

export const deleteCourse = courseId => dispatch => {
  // The action simply redirects to the home page, so this actionType doesn't
  // have any listeners. But there are errors if the payload is not handled.
  return API.deleteCourse(courseId)
    .then(resp => dispatch({ actionType: types.DELETED_COURSE, data: resp }));
};

// General-purpose
export const remove = (model, courseId, data) => dispatch => {
  const actionType = types[`${model.toUpperCase()}_MODIFIED`];
  return API.modify(model, courseId, data, false)
    .then(resp => dispatch({ actionType, data: resp }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

export const checkCourse = (key, courseId) => dispatch => {
  return API.fetch(courseId, 'check')
    .then(resp => {
      const message = resp.course_exists ? I18n.t('courses.creator.already_exists') : null;
      return dispatch({
        actionType: types.CHECK_SERVER,
        data: {
          key,
          message
        }
      });
    })
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

export const greetStudents = (courseId) => dispatch => {
  return API.greetStudents(courseId)
    .then(resp => dispatch({ actionType: types.GREETED_STUDENTS, data: resp }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

// This action is not handled by any store.
export const updateSalesforceRecord = (courseId) => dispatch => {
  return API.updateSalesforceRecord(courseId)
    .then(resp => dispatch({ actionType: types.UPDATED_SALESFORCE_RECORD, data: resp }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

export const notifyOverdue = courseId => dispatch => {
  return API.notifyOverdue(courseId)
    .then(resp => dispatch({ actionType: types.NOTIFIED_OVERDUE, data: resp }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

export const fetchTrainingModule = (opts = {}) => dispatch => {
  return API.fetchTrainingModule(opts)
    .then(resp => dispatch({ actionType: types.RECEIVE_TRAINING_MODULE, data: _.extend(resp, { slide: opts.current_slide_id }) }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

export const fetchAllTrainingModules = () => dispatch => {
  return API.fetchAllTrainingModules()
    .then(resp => dispatch({ actionType: types.RECEIVE_ALL_TRAINING_MODULES, data: resp }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};

export const setSlideCompleted = (opts) => dispatch => {
  return API.setSlideCompleted(opts)
    .then(resp => dispatch({ actionType: types.SLIDE_COMPLETED, data: resp }))
    .catch(resp => dispatch({ actionType: types.API_FAIL, data: resp }));
};