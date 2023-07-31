import React from 'react';
import PropTypes from 'prop-types';

// Components
import Assignment from './Assignment/Assignment.jsx';
import List from '@components/common/list.jsx';
import ArticleUtils from '../../../../../../utils/article_utils.js';

export const AssignmentsList = ({ assignments, course, current_user, fetchArticleDetails, title, user }) => {
  const options = { desktop_only: false, sortable: false };
  const keys = {
    article_name: {
      label: I18n.t('instructor_view.assignments_table.article_name'),
      ...options
    },
    relevant_links: {
      label: I18n.t('instructor_view.assignments_table.relevant_links'),
      ...options
    },
    current_stage: {
      label: course.progress_tracker_enabled ? I18n.t('instructor_view.assignments_table.current_stage') : null,
      ...options
    },
    article_viewer: {
      label: I18n.t(`courses.${ArticleUtils.projectSuffix(course.home_wiki.project, 'article_viewer')}`),
      ...options
    }
  };

  const rows = assignments.map(assignment => (
    <Assignment
      key={assignment.id}
      assignment={assignment}
      course={course}
      current_user={current_user}
      fetchArticleDetails={fetchArticleDetails}
      user={user}
    />
  ));

  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">{ title }</h4>
      <List
        elements={rows}
        className="table--expandable table--hoverable"
        keys={keys}
        table_key="users"
        stickyHeader={false}
        sortable={false}
      />
    </div>
  );
};

AssignmentsList.propTypes = {
  assignments: PropTypes.arrayOf(
    PropTypes.shape({ id: PropTypes.number.isRequired })
  ).isRequired,
  course: PropTypes.shape({
    type: PropTypes.string.isRequired
  }).isRequired,
  current_user: PropTypes.object.isRequired,
  fetchArticleDetails: PropTypes.func.isRequired,
  title: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired
};

export default AssignmentsList;
