import { combineReducers } from 'redux';
import articleDetails from './article_details';
import categories from './categories';
import confirm from './confirm';
import course from './course';
import courseCreator from './course_creator';
import didYouKnow from './did_you_know';
import feedback from './feedback';
import needHelpAlert from './need_help_alert';
import newAccount from './new_account';
import notifications from './notifications';
import recentEdits from './recent_edits.js';
import recentUploads from './recent_uploads';
import revisions from './revisions';
import suspectedPlagiarism from './suspected_plagiarism';
import trainingStatus from './training_status';
import ui from './ui';
import userCourses from './user_courses';
import userProfile from './user_profile';
import users from './users';


const reducer = combineReducers({
  articleDetails,
  categories,
  confirm,
  course,
  courseCreator,
  currentUserFromHtml: (state = {}) => state, // only set from preloaded state
  didYouKnow,
  feedback,
  needHelpAlert,
  newAccount,
  notifications,
  recentEdits,
  recentUploads,
  revisions,
  suspectedPlagiarism,
  trainingStatus,
  ui,
  userCourses,
  userProfile,
  users
});

export default reducer;
