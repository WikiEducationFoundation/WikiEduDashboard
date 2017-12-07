import { combineReducers } from 'redux';
import articleDetails from './article_details.js';
import categories from './categories.js';
import confirm from './confirm.js';
import needHelpAlert from './need_help_alert.js';
import feedback from './feedback.js';
import userCourses from './user_courses.js';
import ui from './ui.js';
import didYouKnow from './did_you_know.js';

const reducer = combineReducers({
  articleDetails,
  categories,
  confirm,
  feedback,
  needHelpAlert,
  userCourses,
  ui,
  didYouKnow,
});

export default reducer;
