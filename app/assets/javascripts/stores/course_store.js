import _ from 'lodash';
import McFly from 'mcfly';
const Flux = new McFly();
import ServerActions from '../actions/server_actions.js';

// Data
let _course = {};
let _persisted = {};
let _loaded = false;
let _renamed = false;

const nameHasChanged = () => {
  if (_course.title !== _persisted.title) { return true; }
  if (_course.term !== _persisted.term) { return true; }
  if (_course.school !== _persisted.school) { return true; }
  return false;
};

// Utilities
const setCourse = function (data, persisted = false, quiet = false) {
  _loaded = true;
  $.extend(true, _course, data);
  delete _course.weeks;
  _renamed = nameHasChanged();
  if (persisted) { _persisted = $.extend(true, {}, _course); }
  if (!quiet) { return CourseStore.emitChange(); }
};

const clearError = () => _course.error = undefined;

const updateCourseValue = function (key, value) {
  _course[key] = value;
  return CourseStore.emitChange();
};

const addCourse = () =>
  setCourse({
    title: '',
    description: '',
    school: '',
    term: '',
    level: '',
    subject: '',
    expected_students: '0',
    start: null,
    end: null,
    day_exceptions: '',
    weekdays: '0000000',
    editingSyllabus: false
  });
const _dismissNotification = function (payload) {
  const notifications = _course.survey_notifications;
  const { id } = payload.data;
  const index = _.indexOf(notifications, _.where(notifications, { id })[0]);
  delete _course.survey_notifications[index];
  return CourseStore.emitChange();
};

const _handleSyllabusUploadResponse = function (data) {
  if (data.url.indexOf('missing.png') > -1) { return undefined; }
  return data.url;
};

// Store
const CourseStore = Flux.createStore(
  {
    getCourse() {
      return _course;
    },
    getCurrentWeek() {
      return Math.max(moment().startOf('week').diff(moment(_course.timeline_start).startOf('week'), 'weeks'), 0);
    },
    restore() {
      _course = $.extend(true, {}, _persisted);
      return CourseStore.emitChange();
    },
    isLoaded() {
      return _loaded;
    },
    isRenamed() {
      return _renamed;
    }
  }
  , (payload) => {
    const { data } = payload;
    clearError();
    switch (payload.actionType) {
      case 'DISMISS_SURVEY_NOTIFICATION':
        _dismissNotification(payload);
        break;
      case 'RECEIVE_COURSE': case 'CREATED_COURSE': case 'CAMPAIGN_MODIFIED': case 'SAVED_COURSE': case 'CHECK_COURSE': case 'PERSISTED_COURSE':
        setCourse(data.course, true);
        break;
      case 'UPDATE_CLONE': case 'RECEIVE_COURSE_CLONE':
        setCourse(data.course, true);
        break;
      case 'UPDATE_COURSE':
        setCourse(data.course);
        if (data.save) {
          ServerActions.saveCourse($.extend(true, {}, { course: _course }), data.course.slug);
        }
        break;
      case 'SYLLABUS_UPLOAD_SUCCESS':
        setCourse({
          uploadingSyllabus: false,
          editingSyllabus: false
        });
        updateCourseValue('syllabus', _handleSyllabusUploadResponse(data));
        break;
      case 'UPLOADING_SYLLABUS':
        setCourse({ uploadingSyllabus: true });
        break;
      case 'TOGGLE_EDITING_SYLLABUS':
        setCourse({ editingSyllabus: data.bool });
        break;
      case 'ADD_COURSE':
        addCourse();
        break;
      case 'RECEIVE_INITIAL_CAMPAIGN':
        setCourse({
          initial_campaign_id: data.campaign.id,
          initial_campaign_title: data.campaign.title,
          description: data.campaign.template_description
        });
        break;
      case 'ENABLE_CHAT_SUCCEEDED':
        setCourse({ flags: { enable_chat: true } });
        break;
      case 'LINKED_TO_SALESFORCE':
        setCourse({ flags: data.flags });
        break;
      default:
      // no default
    }
    return true;
  }
);

export default CourseStore;
