import SurveyAdmin from './modules/SurveyAdmin.coffee';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.coffee';

$(() => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
});
