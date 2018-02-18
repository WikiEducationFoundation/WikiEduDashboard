import React from 'react';
import YesNoSelector from './yes_no_selector';

const PrivacySelector = ({ course, editable }) => {
  return (
    <YesNoSelector
      courseProperty="private"
      label={I18n.t("courses.private")}
      course={course}
      editable={editable}
    />
  );
};

export default PrivacySelector;
