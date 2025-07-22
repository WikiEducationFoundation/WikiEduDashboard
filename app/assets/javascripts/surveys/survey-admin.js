import SurveyAdmin from './modules/SurveyAdmin.js';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.js';

window.onload = () => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
};
