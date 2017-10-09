import { combineReducers } from 'redux';
import articleDetails from './article_details.js';
import needHelpAlert from './need_help_alert.js';
import feedback from './feedback.js';
import userCourses from './user_courses.js';
import ui from './ui.js';

const reducer = combineReducers({
  articleDetails,
  feedback,
  needHelpAlert,
  userCourses,
  ui
});

export default reducer;
