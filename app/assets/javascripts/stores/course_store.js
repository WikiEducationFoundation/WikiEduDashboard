import _ from 'lodash';
import McFly from 'mcfly';
const Flux = new McFly();
import ServerActions from '../actions/server_actions.js';

// Data
let _course = {};
let _persisted = {};
let _loaded = false;


// Utilities
const setCourse = function (data, persisted = false) {
  _loaded = true;
  $.extend(true, _course, data);
  delete _course.weeks;
  if (persisted) { _persisted = $.extend(true, {}, _course); }
};

const updateCourseValue = function (key, value) {
  _course[key] = value;
};

const addCourse = () =>
  setCourse({
    title: '',
    description: '',
    school: '',
    term: '',
    subject: '',
    expected_students: '0',
    start: null,
    end: null,
    day_exceptions: '',
    weekdays: '0000000',
    editingSyllabus: false
  })
;

const _dismissNotification = function (payload) {
  const notifications = _course.survey_notifications;
  const { id } = payload.data;
  const index = _.indexOf(notifications, _.where(notifications, { id })[0]);
  delete _course.survey_notifications[index];
};

const _getUrlFromSyllabusUploadResponse = function (data) {
  if (data.url.indexOf('missing.png') > -1) { return undefined; }
  return data.url;
};

const storeMethods = {
  getCourse() {
    return _course;
  },
  getCurrentWeek() {
    return Math.max(moment().startOf('week').diff(moment(_course.timeline_start).startOf('week'), 'weeks'), 0);
  },
  isLoaded() {
    return _loaded;
  }
};

// Store
const CourseStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'DISMISS_SURVEY_NOTIFICATION':
      _dismissNotification(payload);
      CourseStore.emitChange();
      break;
    case 'RECEIVE_COURSE': case 'CREATED_COURSE': case 'CAMPAIGN_MODIFIED': case 'SAVED_COURSE': case 'CHECK_COURSE': case 'PERSISTED_COURSE':
      setCourse(data.course, true);
      CourseStore.emitChange();
      break;
    case 'UPDATE_CLONE': case 'RECEIVE_COURSE_CLONE':
      setCourse(data.course, true);
      CourseStore.emitChange();
      break;
    case 'UPDATE_COURSE':
      setCourse(data.course);
      CourseStore.emitChange();
      if (data.save) {
        ServerActions.saveCourse($.extend(true, {}, { course: _course }), data.course.slug);
      }
      break;
    case 'SYLLABUS_UPLOAD_SUCCESS':
      updateCourseValue('syllabus', _getUrlFromSyllabusUploadResponse(data));
      setCourse({
        uploadingSyllabus: false,
        editingSyllabus: false
      });
      CourseStore.emitChange();
      break;
    case 'UPLOADING_SYLLABUS':
      setCourse({ uploadingSyllabus: true });
      CourseStore.emitChange();
      break;
    case 'TOGGLE_EDITING_SYLLABUS':
      setCourse({ editingSyllabus: data.bool });
      CourseStore.emitChange();
      break;
    case 'ADD_COURSE':
      addCourse();
      CourseStore.emitChange();
      break;
    default:
      // no default
  }
  return true;
});

CourseStore.restore = function () {
  _course = $.extend(true, {}, _persisted);
  return CourseStore.emitChange();
};

export default CourseStore;
