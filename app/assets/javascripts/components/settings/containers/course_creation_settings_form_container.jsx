import { connect } from 'react-redux';
import { updateCourseCreationSettings } from '../../../actions/settings_actions';
import CourseCreationSettingsForm from '../views/course_creation_settings_form.jsx';

const mapDispatchToProps = {
  updateCourseCreationSettings,
};

export default connect(null, mapDispatchToProps)(CourseCreationSettingsForm);
