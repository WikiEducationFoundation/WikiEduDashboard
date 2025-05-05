import React from 'react';
import YesNoSelector from './yes_no_selector';

const NoSandboxesToggle = ({ course, editable, updateCourse }) => {
  if (!Features.wikiEd) { return null; }

  return (
    <YesNoSelector
      courseProperty="no_sandboxes"
      label={I18n.t('courses.no_sandboxes')}
      tooltip={I18n.t('courses.no_sandboxes_info')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default NoSandboxesToggle;
