import SurveyAdmin from './modules/SurveyAdmin.js';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.js';

$(() => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
});
