import { combineReducers } from 'redux';
import articleDetails from './article_details';
import categories from './categories';
import confirm from './confirm';
import course from './course';
import courseCreator from './course_creator';
import didYouKnow from './did_you_know';
import feedback from './feedback';
import needHelpAlert from './need_help_alert';
import notifications from './notifications';
import recentEdits from './recent_edits.js';
import revisions from './revisions';
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
  currentUserFromHtml: (state = null) => state, // only set from preloaded state
  didYouKnow,
  feedback,
  needHelpAlert,
  notifications,
  recentEdits,
  revisions,
  ui,
  userCourses,
  userProfile,
  users
});

export default reducer;
