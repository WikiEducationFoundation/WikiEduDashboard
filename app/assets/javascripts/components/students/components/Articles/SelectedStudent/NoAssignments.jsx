import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../../utils/article_utils';

export const NoAssignments = ({ project }) => {
  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">
        {I18n.t('articles.assigned')}
      </h4>
      <section className="no-assignments">
        <p>{ I18n.t(`instructor_view.${ArticleUtils.projectSuffix(project, 'no_assignments')}`) }</p>
      </section>
    </div>
  );
};

NoAssignments.propTypes = {
  project: PropTypes.string.isRequired
};

export default NoAssignments;
