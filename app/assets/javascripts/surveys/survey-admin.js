import SurveyAdmin from './modules/SurveyAdmin.js';
import SurveyAssignmentAdmin from './modules/SurveyAssignmentAdmin.js';

// Toggle function for survey preview dropdown (similar to FAQ accordion)
const toggleSurveyPreviewDropdown = (id) => {
  const element = document.getElementById(id);
  if (element.className.indexOf('collapsed') === -1) {
    element.className = element.className.replace('expanded', 'collapsed');
  } else {
    element.className = element.className.replace('collapsed', 'expanded');
  }
};

window.toggleSurveyPreviewDropdown = toggleSurveyPreviewDropdown;

window.onload = () => {
  SurveyAdmin.init();
  return SurveyAssignmentAdmin.init();
};
