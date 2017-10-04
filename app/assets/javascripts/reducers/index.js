import { combineReducers } from 'redux';
import articleDetails from './article_details.js';
import needHelpAlert from './need_help_alert.js';
import feedback from './feedback.js';
import ui from './ui.js';
import ConfirmationStore from './confirmation.js';

const reducer = combineReducers({
  articleDetails,
  feedback,
  needHelpAlert,
  ui,
  ConfirmationStore
});

export default reducer;
