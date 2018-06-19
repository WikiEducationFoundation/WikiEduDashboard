import React from 'react';
import YesNoSelector from './yes_no_selector';

const TimelineToggle = ({ course, editable }) => {
  return (
    <YesNoSelector
      courseProperty="timeline_enabled"
      label={I18n.t("courses.timeline_enabled")}
      tooltip={I18n.t("courses.timeline_tooltip")}
      course={course}
      editable={editable}
    />
  );
};

export default TimelineToggle;
