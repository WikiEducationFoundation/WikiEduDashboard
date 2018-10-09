import McFly from 'mcfly';
import _ from 'lodash';
import API from '../utils/api.js';
const Flux = new McFly();

const ServerActions = Flux.createActions({

  // General-purpose
  remove(model, courseId, data) {
    const actionType = `${model.toUpperCase()}_MODIFIED`;
    return API.modify(model, courseId, data, false)
      .then(resp => ({ actionType, data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchAllTrainingModules() {
    return API.fetchAllTrainingModules()
      .then(resp => ({ actionType: 'RECEIVE_ALL_TRAINING_MODULES', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchTrainingModule(opts = {}) {
    return API.fetchTrainingModule(opts)
      .then(resp => ({ actionType: 'RECEIVE_TRAINING_MODULE', data: _.extend(resp, { slide: opts.current_slide_id }) }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  setSlideCompleted(opts) {
    return API.setSlideCompleted(opts)
      .then(resp => ({ actionType: 'SLIDE_COMPLETED', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  checkCourse(key, courseId) {
    return API.fetch(courseId, 'check')
      .then(resp => {
        const message = resp.course_exists ? I18n.t('courses.creator.already_exists') : null;
        return {
          actionType: 'CHECK_SERVER',
          data: {
            key,
            message
          }
        };
      })
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  deleteCourse(courseId) {
    // The action simply redirects to the home page, so this actionType doesn't
    // have any listeners. But there are errors if the payload is not handled.
    return API.deleteCourse(courseId)
      .then(resp => ({ actionType: 'DELETED_COURSE', data: resp }));
  },

  // This action is not handled by any store.
  updateSalesforceRecord(courseId) {
    return API.updateSalesforceRecord(courseId)
      .then(resp => ({ actionType: 'UPDATED_SALESFORCE_RECORD', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  notifyOverdue(courseId) {
    return API.notifyOverdue(courseId)
      .then(resp => ({ actionType: 'NOTIFIED_OVERDUE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  greetStudents(courseId) {
    return API.greetStudents(courseId)
      .then(resp => ({ actionType: 'GREETED_STUDENTS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export default ServerActions;
