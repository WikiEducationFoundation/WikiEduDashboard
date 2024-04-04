import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../../utils/article_utils';

export const NoAssignments = ({ student, current_user, project }) => {
  let isCurrentUser;
  if (student) { isCurrentUser = current_user.id === student.id; }
  const instructorOrAdmin = current_user.isInstructor || current_user.admin;
  const permitted = (isCurrentUser || instructorOrAdmin);

  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">
        {I18n.t('articles.assigned')}
      </h4>
      <section className="no-assignments">
        <p>{ I18n.t(`instructor_view.${ArticleUtils.projectSuffix(project, 'no_assignments')}`) } {permitted && I18n.t('instructor_view.can_assign_assignments') }</p>
      </section>
    </div>
  );
};

NoAssignments.propTypes = {
  current_user: PropTypes.object,
  student: PropTypes.object,
  project: PropTypes.string.isRequired
};

export default NoAssignments;
