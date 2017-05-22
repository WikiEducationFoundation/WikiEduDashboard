import { combineReducers } from 'redux';
import articleDetails from './article_details.js';
import needHelpAlert from './need_help_alert.js';
import ui from './ui.js';

const reducer = combineReducers({
  articleDetails,
  needHelpAlert,
  ui
});

export default reducer;
