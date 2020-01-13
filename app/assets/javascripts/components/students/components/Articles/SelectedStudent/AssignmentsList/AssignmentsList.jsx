import React from 'react';
import PropTypes from 'prop-types';

// Components
import Assignment from './Assignment/Assignment.jsx';
import List from '@components/common/list.jsx';

export const AssignmentsList = ({ assignments, course, title, user }) => {
  const options = { desktop_only: false, sortable: false };
  const keys = {
    article_name: { label: 'Article Name', ...options },
    relevant_links: { label: 'Relevant Links', ...options },
    current_stage: { label: 'Current Stage', ...options }
  };

  const rows = assignments.map(assignment => (
    <Assignment
      key={assignment.id}
      assignment={assignment}
      courseType={course.type}
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
  title: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired
};

export default AssignmentsList;
