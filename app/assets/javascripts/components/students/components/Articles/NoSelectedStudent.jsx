import React from 'react';
import PropTypes from 'prop-types';

// Utils
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';

export const NoSelectedStudent = ({ string_prefix }) => {
  const prefix = CourseUtils.i18n('student', string_prefix);
  return (
    <div className="no-selected-student">
      <h4>{ I18n.t('instructor_view.select_student.title', { prefix }) }</h4>
      <p>{ I18n.t('instructor_view.select_student.content') }</p>
    </div>
  );
};


NoSelectedStudent.propTypes = {
  string_prefix: PropTypes.string.isRequired
};

export default NoSelectedStudent;
