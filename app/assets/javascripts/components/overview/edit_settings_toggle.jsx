import React from 'react';
import YesNoSelector from './yes_no_selector';

const EditSettingsToggle = ({ course, editable, updateCourse }) => {
  return (
    <div>
      <YesNoSelector
        courseProperty="assignment_edits_enabled"
        label={I18n.t('courses.assignment_edits_enabled')}
        tooltip={I18n.t('courses.assignment_edits_enabled_tooltip')}
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
      <YesNoSelector
        courseProperty="wiki_course_page_enabled"
        label={I18n.t('courses.wiki_course_page_enabled')}
        tooltip={I18n.t('courses.wiki_course_page_enabled_tooltip')}
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
      <YesNoSelector
        courseProperty="enrollment_edits_enabled"
        label={I18n.t('courses.enrollment_edits_enabled')}
        tooltip={I18n.t('courses.enrollment_edits_enabled_tooltip')}
        course={course}
        editable={editable}
        updateCourse={updateCourse}
      />
    </div>
  );
};

export default EditSettingsToggle;
