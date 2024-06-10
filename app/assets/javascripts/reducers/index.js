import { combineReducers } from 'redux';
import alerts from './alerts';
import articleDetails from './article_details';
import articleFinder from './article_finder';
import articles from './articles';
import badWorkAlert from './bad_work_alert';
import assignments from './assignments';
import campaign from './campaign';
import campaigns from './campaigns';
import categories from './categories';
import confirm from './confirm';
import course from './course';
import courseAlerts from './course_alerts';
import courseCreator from './course_creator';
import didYouKnow from './did_you_know';
import exercises from './exercises';
import feedback from './feedback';
import needHelpAlert from './need_help_alert';
import newAccount from './new_account';
import notifications from './notifications';
import persistedCourse from './persisted_course';
import recentEdits from './recent_edits.js';
import recentUploads from './recent_uploads';
import revisions from './revisions';
import suspectedPlagiarism from './suspected_plagiarism';
import settings from './settings';
import tags from './tags';
import tickets from './tickets';
import timeline from './timeline';
import training from './training';
import trainingStatus from './training_status';
import userTrainingStatus from './user_training_status';
import ui from './ui';
import uploads from './uploads';
import userCourses from './user_courses';
import userProfile from './user_profile';
import userRevisions from './user_revisions';
import users from './users';
import validations from './validations';
import wikidataLabels from './wikidata_labels';
import wizard from './wizard';
import course_search_results from './course_search_results';
import active_courses from './active_courses';
import wiki_courses from './wiki_courses';
import refreshing from './refreshing';
import scopingMethods from './scoping_methods';
import adminCourseNotes from './admin_course_notes';
import instructorAlert from './instructor_alert';

const reducer = combineReducers({
  active_courses,
  admins: (state = {}) => state, // only set from preloaded state
  alerts,
  articleDetails,
  articleFinder,
  articles,
  assignments,
  badWorkAlert,
  campaign,
  campaigns,
  categories,
  confirm,
  course,
  courseAlerts,
  courseCreator,
  adminCourseNotes,
  course_search_results,
  currentUserFromHtml: (state = {}) => state, // only set from preloaded state
  didYouKnow,
  exercises,
  feedback,
  instructorAlert,
  needHelpAlert,
  newAccount,
  notifications,
  persistedCourse,
  recentEdits,
  recentUploads,
  refreshing,
  revisions,
  suspectedPlagiarism,
  settings,
  tags,
  tickets,
  timeline,
  scopingMethods,
  training,
  trainingStatus,
  ui,
  uploads,
  userCourses,
  userProfile,
  userRevisions,
  userTrainingStatus,
  users,
  validations,
  wikidataLabels,
  wiki_courses,
  wizard
});

export default reducer;
