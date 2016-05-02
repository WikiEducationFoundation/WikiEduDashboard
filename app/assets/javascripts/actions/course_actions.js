import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.coffee';

const CourseActions = Flux.createActions({
  persistCourse(data, courseId = null) {
    return API.saveCourse(data, courseId)
      .then(resp => {
        return {
          actionType: 'PERSISTED_COURSE',
          data: resp
        };
      })
      .catch(resp => {
        return {
          actionType: 'API_FAIL',
          data: resp
        };
      });
  },

  updateCourse(course, save = false) {
    return {
      actionType: 'UPDATE_COURSE',
      data: {
        course,
        save
      }
    };
  },

  setValid(key, isValid) {
    return {
      actionType: 'SET_INVALID_KEY',
      data: {
        key,
        valid: isValid
      }
    };
  },

  save() {
    return {
      actionType: 'SAVE_COURSE'
    };
  },

  addCourse() {
    return {
      actionType: 'ADD_COURSE'
    };
  },

  setCourse(course) {
    return {
      actionType: 'RECEIVE_COURSE',
      data: {
        course
      }
    };
  },

  updateClonedCourse(data, courseId, tempId) {
    // Ensure course name is unique
    return API.fetch(tempId, 'check')
      .then(resp => {
        // Course name is all good... save it
        if (!resp.course_exists) {
          return CourseActions.persistCourse(data, courseId);
        }

        // Invalidate if course name taken
        const message = 'This course already exists. Consider changing the name, school, or term to make it unique.';
        return {
          actionType: 'CHECK_SERVER',
          data: {
            key: 'exists',
            message
          }
        };
      })
      .catch(resp => {
        return {
          actionType: 'API_FAIL',
          data: resp
        };
      });
  },

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
  }
});

export default CourseActions;
