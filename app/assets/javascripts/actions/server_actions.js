import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.coffee';
import _ from 'lodash';

const ServerActions = Flux.createActions({

  // General-purpose
  fetch(model, courseId) {
    const actionType = `RECEIVE_${model.toUpperCase()}`;
    return API.fetch(courseId, model)
      .then(resp => ({ actionType, data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  add(model, courseId, data) {
    const actionType = `${model.toUpperCase()}_MODIFIED`;
    return API.modify(model, courseId, data, true)
      .then(resp => ({ actionType, data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  remove(model, courseId, data) {
    const actionType = `${model.toUpperCase()}_MODIFIED`;
    return API.modify(model, courseId, data, false)
      .then(resp => ({ actionType, data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  // Specific
  cloneCourse(courseId) {
    return API.cloneCourse(courseId)
      .then(resp => ({ actionType: 'RECEIVE_COURSE_CLONE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchLookups(key) {
    return API.fetchLookups(key)
      .then(resp => ({
        actionType: 'RECEIVE_LOOKUPS',
        data: {
          model: resp.model,
          values: resp.values
        }
      }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchWizardIndex() {
    return API.fetchWizardIndex()
      .then(resp => ({
        actionType: 'RECEIVE_WIZARD_INDEX',
        data: {
          wizard_index: resp
        }
      }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchWizardPanels(wizardId) {
    return API.fetchWizardPanels(wizardId)
      .then(resp => ({
        actionType: 'RECEIVE_WIZARD_PANELS',
        data: {
          wizard_panels: resp
        }
      }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchCohorts() {
    return API.fetchCohorts()
      .then(resp => ({ actionType: 'RECEIVE_COHORTS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchRevisions(studentId, courseId) {
    return API.fetchRevisions(studentId, courseId)
      .then(resp => ({ actionType: 'RECEIVE_REVISIONS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchDYKArticles(opts = {}) {
    return API.fetchDykArticles(opts)
      .then(resp => ({ actionType: 'RECEIVE_DYK', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchSuspectedPlagiarism(opts = {}) {
    return API.fetchSuspectedPlagiarism(opts)
      .then(resp => ({ actionType: 'RECEIVE_SUSPECTED_PLAGIARISM', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchRecentEdits(opts = {}) {
    return API.fetchRecentEdits(opts)
      .then(resp => ({ actionType: 'RECEIVE_RECENT_EDITS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchRecentUploads(opts = {}) {
    return API.fetchRecentUploads(opts)
      .then(resp => ({ actionType: 'RECEIVE_RECENT_UPLOADS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchUserAssignments(opts) {
    return API.fetchUserAssignments(opts)
      .then(resp => ({ actionType: 'RECEIVE_USER_ASSIGNMENTS', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  deleteAssignment(assignment) {
    return API.deleteAssignment(assignment)
      .then(resp => ({ actionType: 'DELETE_USER_ASSIGNMENT', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  addAssignment(opts) {
    return API.createAssignment(opts)
      .then(resp => ({ actionType: 'CREATE_USER_ASSIGNMENT', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchCoursesForUser(userId) {
    return API.fetchUserCourses(userId)
      .then(resp => ({ actionType: 'RECEIVE_USER_COURSES', data: resp }))
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

  // Save
  saveCourse(data, courseId = null) {
    const actionType = courseId === null ? 'CREATED_COURSE' : 'SAVED_COURSE';
    return API.saveCourse(data, courseId)
      .then(resp => ({ actionType, data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  updateClone(data, courseId) {
    return API.saveCourse(data, courseId)
      .then(resp => ({ actionType: 'UPDATE_CLONE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  saveStudents() {
    return null;
  },

  saveTimeline(data, courseId) {
    return API.saveTimeline(courseId, data)
      .then(resp => ({ actionType: 'SAVED_TIMELINE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  saveGradeables(data, courseId) {
    return API.saveGradeables(courseId, data)
      .then(resp => ({ actionType: 'SAVED_TIMELINE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  submitWizard(courseId, wizardId, data) {
    return API.submitWizard(courseId, wizardId, data)
      .then(resp => ({ actionType: 'WIZARD_SUBMITTED', data: resp }))
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
    // This redirects, no need for an action to be broadcast
    return API.deleteCourse(courseId);
  },

  manualUpdate(courseId) {
    return API.manualUpdate(courseId)
      .then(resp => ({ actionType: 'MANUAL_UPDATE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  notifyOverdue(courseId) {
    return API.notifyOverdue(courseId)
      .then(resp => ({ actionType: 'NOTIFIED_OVERDUE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export default ServerActions;
