import { reject } from 'lodash-es';
import {
  RECEIVE_INITIAL_CAMPAIGN,
  RECEIVE_COURSE_CLONE,
  RECEIVE_COURSE,
  RECEIVE_COURSE_UPDATE,
  PERSISTED_COURSE,
  UPDATE_COURSE,
  CREATED_COURSE,
  ADD_CAMPAIGN,
  DELETE_CAMPAIGN,
  DISMISS_SURVEY_NOTIFICATION,
  TOGGLE_EDITING_SYLLABUS,
  START_SYLLABUS_UPLOAD,
  SYLLABUS_UPLOAD_SUCCESS,
  LINKED_TO_SALESFORCE
} from '../constants';
import CourseUtils from '../utils/course_utils';

const initialState = {
  title: '',
  description: '',
  school: '',
  term: '',
  level: '',
  subject: '',
  expected_students: '0',
  format: '',
  start: null,
  end: null,
  timeline_start: null,
  timeline_end: null,
  home_wiki: { language: 'en', project: 'wikipedia' },
  day_exceptions: '',
  weekdays: '0000000',
  editingSyllabus: false,
  training_library_slug: 'students',
  loading: true,
  updates: {},
  wikis: [],
  namespaces: [],
  article_count: 0,
  course_stats: {}
};


export default function course(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_COURSE:
      return { loading: false, ...action.data.course };
    case RECEIVE_COURSE_UPDATE: {
      const courseData = action.data.course;
      const newStats = CourseUtils.newCourseStats(state, courseData);
      const newKeys = CourseUtils.courseStatsToUpdate(courseData, newStats);

      return {
        ...state,
        ...newKeys,
        newStats,
        flags: {
          ...courseData.flags,
        },
      };
    }
    case PERSISTED_COURSE:
      return { ...state, ...action.data.course };
    case UPDATE_COURSE:
      return { ...state, ...action.course };
    case CREATED_COURSE:
      return { loading: false, ...action.data.course };
    case RECEIVE_INITIAL_CAMPAIGN: {
      const campaign = action.data.campaign;
      return {
        ...state,
        initial_campaign_id: campaign.id,
        initial_campaign_title: campaign.title,
        description: campaign.template_description,
        type: campaign.default_course_type,
        passcode: campaign.default_passcode
      };
    }
    case ADD_CAMPAIGN:
    case DELETE_CAMPAIGN:
      return { ...state, published: action.data.course.published };
    case RECEIVE_COURSE_CLONE:
      return { loading: false, ...action.data.course };
    case DISMISS_SURVEY_NOTIFICATION: {
      return {
        ...state,
        survey_notifications: reject(state.survey_notifications, { id: action.id })
      };
    }
    case TOGGLE_EDITING_SYLLABUS:
      return { ...state, editingSyllabus: !state.editingSyllabus };
    case START_SYLLABUS_UPLOAD:
      return { ...state, uploadingSyllabus: true };
    case SYLLABUS_UPLOAD_SUCCESS:
      return {
        ...state,
        uploadingSyllabus: false,
        editingSyllabus: false,
        syllabus: action.syllabus
      };
    case LINKED_TO_SALESFORCE:
      return { ...state, flags: action.data.flags };
    default:
      return state;
  }
}
