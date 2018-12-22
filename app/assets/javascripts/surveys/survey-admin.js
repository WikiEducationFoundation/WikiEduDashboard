import SurveyAdmin from './modules/SurveyAdmin.js';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.js';
window.$ = require('jquery');

$(() => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
});
