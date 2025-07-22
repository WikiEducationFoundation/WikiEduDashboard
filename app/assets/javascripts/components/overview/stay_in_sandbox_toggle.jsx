import React from 'react';
import YesNoSelector from './yes_no_selector';

const StayInSandboxToggle = ({ course, editable, updateCourse }) => {
  if (!Features.wikiEd) { return null; }

  return (
    <YesNoSelector
      courseProperty="stay_in_sandbox"
      label={I18n.t('courses.stay_in_sandbox')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default StayInSandboxToggle;
