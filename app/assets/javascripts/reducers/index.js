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
import revisions from './revisions';
import ui from './ui';
import userCourses from './user_courses';

const reducer = combineReducers({
  articleDetails,
  categories,
  confirm,
  course,
  courseCreator,
  didYouKnow,
  feedback,
  needHelpAlert,
  notifications,
  revisions,
  ui,
  userCourses
});

export default reducer;
