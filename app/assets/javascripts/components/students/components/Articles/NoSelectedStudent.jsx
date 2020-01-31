import React from 'react';
import PropTypes from 'prop-types';

export const NoSelectedStudent = ({ prefix }) => (
  <div className="no-selected-student">
    <h4>{ I18n.t('instructor_view.select_student.title', { prefix }) }</h4>
    <p>{ I18n.t('instructor_view.select_student.content') }</p>
  </div>
);

NoSelectedStudent.propTypes = {
  prefix: PropTypes.string.isRequired
};

export default NoSelectedStudent;
