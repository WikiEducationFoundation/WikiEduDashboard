import React from 'react';
import YesNoSelector from './yes_no_selector';
import ArticleUtils from '../../utils/article_utils';

const RetainAvailableArticlesToggle = ({ course, editable, updateCourse }) => {
  if (!Features.wikiEd) { return null; }
  return (
    <YesNoSelector
      courseProperty="retain_available_articles"
      label={I18n.t(`courses.${ArticleUtils.projectSuffix(course.home_wiki.project, 'retain_available_articles')}`)}
      tooltip={I18n.t(`courses.${ArticleUtils.projectSuffix(course.home_wiki.project, 'retain_available_articles_info')}`)}
      course={course}
      editable={editable}
      updateCourse={updateCourse}
    />
  );
};

export default RetainAvailableArticlesToggle;
