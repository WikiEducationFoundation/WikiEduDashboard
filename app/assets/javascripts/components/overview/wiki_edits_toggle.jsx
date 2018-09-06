import React from 'react';
import YesNoSelector from './yes_no_selector';

const WikiEditsToggle = ({ course, editable, updateCourse }) => {
  return (
    <YesNoSelector
      courseProperty="wiki_edits_enabled"
      label={I18n.t('courses.wiki_edits_enabled')}
      tooltip={I18n.t('courses.wiki_edits_enabled_tooltip')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default WikiEditsToggle;
