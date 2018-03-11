import React from 'react';
import YesNoSelector from '../../actions/course_actions.js';

const CourseEditToggle = ({ course, editable }) => {
  return (
    <YesNoSelector
      courseProperty="course_edit_enabled"
      label={I18n.t("courses.course_edit_enabled")}
      course={course}
      editable={editable}
    />
    );
};

export default CourseEditToggle;
