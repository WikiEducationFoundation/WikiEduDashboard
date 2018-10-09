import React from 'react';
import YesNoSelector from './yes_no_selector';

const TimelineToggle = ({ course, editable, updateCourse }) => {
  return (
    <YesNoSelector
      courseProperty="timeline_enabled"
      label={I18n.t('courses.timeline_enabled')}
      tooltip={I18n.t('courses.timeline_tooltip')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default TimelineToggle;
