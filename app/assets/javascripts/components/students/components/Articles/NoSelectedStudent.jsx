import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../utils/article_utils';

// Utils
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';

export const NoSelectedStudent = ({ string_prefix, project }) => {
  const prefix = CourseUtils.i18n('student', string_prefix);
  return (
    <div className="no-selected-student">
      <h4>{ I18n.t('instructor_view.select_student.title', { prefix }) }</h4>
      <p>{ I18n.t(`instructor_view.select_student.${ArticleUtils.projectSuffix(project, 'content')}`) }</p>
    </div>
  );
};


NoSelectedStudent.propTypes = {
  string_prefix: PropTypes.string.isRequired,
  project: PropTypes.string.isRequired
};

export default NoSelectedStudent;
