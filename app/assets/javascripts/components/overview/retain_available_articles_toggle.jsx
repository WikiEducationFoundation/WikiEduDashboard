import React from 'react';
import YesNoSelector from './yes_no_selector';

const RetainAvailableArticlesToggle = ({ course, editable, updateCourse }) => {
  if (!Features.wikiEd) { return null; }

  return (
    <YesNoSelector
      courseProperty="retain_available_articles"
      label={I18n.t('courses.retain_available_articles')}
      tooltip={I18n.t('courses.retain_available_articles_info')}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default RetainAvailableArticlesToggle;
