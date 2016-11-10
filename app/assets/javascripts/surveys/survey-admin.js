import SurveyAdmin from './modules/SurveyAdmin.coffee';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.js';

$(() => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
});
