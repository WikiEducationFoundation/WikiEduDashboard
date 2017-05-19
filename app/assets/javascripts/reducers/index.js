import { combineReducers } from 'redux';
import ui from './ui.js';
import needHelpAlert from './need_help_alert.js';

const reducer = combineReducers({
  ui,
  needHelpAlert
});

export default reducer;
