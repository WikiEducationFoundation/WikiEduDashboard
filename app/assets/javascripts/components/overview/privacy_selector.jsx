import React from 'react';
import YesNoSelector from './yes_no_selector';

const PrivacySelector = ({ course, editable, updateCourse }) => {
  return (
    <YesNoSelector
      courseProperty="private"
      label={I18n.t('courses.private')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default PrivacySelector;
