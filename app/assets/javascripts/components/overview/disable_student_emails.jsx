import React from 'react';
import YesNoSelector from './yes_no_selector';

const DisableStudentEmailsToggle = ({ course, editable, updateCourse }) => {
  return (
    <YesNoSelector
      courseProperty="disable_student_emails"
      label={I18n.t('courses.disable_student_emails')}
      tooltip={I18n.t('courses.disable_student_emails_tooltip')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default DisableStudentEmailsToggle;
