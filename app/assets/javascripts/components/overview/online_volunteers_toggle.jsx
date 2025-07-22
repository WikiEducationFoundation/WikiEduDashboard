import React from 'react';
import YesNoSelector from './yes_no_selector';

const OnlineVolunteersToggle = ({ course, editable, updateCourse }) => {
  return (
    <YesNoSelector
      courseProperty="online_volunteers_enabled"
      label={I18n.t('courses.online_volunteers_enabled')}
      tooltip={I18n.t('courses.online_volunteers_tooltip')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default OnlineVolunteersToggle;
