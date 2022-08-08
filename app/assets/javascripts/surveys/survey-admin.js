import SurveyAdmin from './modules/SurveyAdmin.js';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.js';

document.onload = () => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
};
