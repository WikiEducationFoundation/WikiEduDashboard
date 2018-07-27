import McFly from 'mcfly';
import API from '../utils/api.js';

const Flux = new McFly();

const CourseActions = Flux.createActions({
  dismissNotification(id) {
    return API.dismissNotification(id)
      .then(() => {
        return {
          actionType: 'DISMISS_SURVEY_NOTIFICATION',
          data: { id }
        };
      })
      .catch(resp => {
        return {
          actionType: 'API_FAIL',
          data: resp
        };
      });
  },

  toggleEditingSyllabus(bool) {
    return {
      actionType: 'TOGGLE_EDITING_SYLLABUS',
      data: { bool }
    };
  },

  startUploadSyllabus() {
    return {
      actionType: 'UPLOADING_SYLLABUS'
    };
  },

  uploadSyllabus(payload) {
    return API.uploadSyllabus(payload)
      .then((data) => {
        return {
          actionType: 'SYLLABUS_UPLOAD_SUCCESS',
          data: { url: data.url }
        };
      })
      .catch(resp => {
        return {
          actionType: 'API_FAIL',
          data: resp
        };
      });
  },

  deleteAllWeeks(courseId) {
    return API.deleteAllWeeks(courseId)
      .then((data) => {
        return {
          actionType: 'DELETE_ALL_WEEKS',
          data: { id: data.courseId }
        };
      })
      .catch(resp => {
        return {
          actionType: 'API_FAIL',
          data: resp
        };
      });
  },
});

export default CourseActions;
