import { combineReducers } from 'redux';
import articleDetails from './article_details.js';
import needHelpAlert from './need_help_alert.js';
import feedback from './feedback.js';
import userCourses from './user_courses.js';
import ui from './ui.js';
import Confirmation from './confirmation.js';
import didYouKnow from './did_you_know.js';

const reducer = combineReducers({
  articleDetails,
  feedback,
  needHelpAlert,
  userCourses,
  ui,
  Confirmation,
  didYouKnow
});

export default reducer;
