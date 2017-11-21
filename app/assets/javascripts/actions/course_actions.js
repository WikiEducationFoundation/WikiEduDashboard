import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

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

  persistAndRedirectCourse(data, courseId, redirect) {
    return API.saveCourse(data, courseId)
      .then(() => redirect())
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

  addCourse() {
    return {
      actionType: 'ADD_COURSE'
    };
  },

  updateClonedCourse(data, courseId, tempId) {
    const redirectToNewSlug = () => {
      window.location = `/courses/${tempId}`;
    };
    // Ensure course name is unique
    return API.fetch(tempId, 'check')
      .then(resp => {
        // Course name is all good... save it
        if (!resp.course_exists) {
          return CourseActions.persistAndRedirectCourse(data, courseId, redirectToNewSlug);
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
