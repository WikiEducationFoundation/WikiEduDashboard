import React from 'react';
import PropTypes from 'prop-types';

// Components
import Assignment from './Assignment/Assignment.jsx';
import List from '@components/common/list.jsx';

export const AssignmentsList = ({ assignments, title }) => {
  const options = { desktop_only: false, sortable: false };
  const keys = {
    article_name: { label: 'Article Name', ...options },
    relevant_links: { label: 'Relevant Links', ...options },
    current_stage: { label: 'Current Stage', ...options }
  };

  const rows = assignments.map(assignment => (
    <Assignment key={assignment.id} assignment={assignment} />
  ));

  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">{ title }</h4>
      <List
        elements={rows}
        className="table--expandable table--hoverable"
        keys={keys}
        table_key="users"
        // none_message={CourseUtils.i18n('students_none', this.props.course.string_prefix)}
        // editable={this.state.editAssignments}
        stickyHeader={false}
        sortable={false}
      />
    </div>
  );
};

AssignmentsList.propTypes = {
  assignments: PropTypes.arrayOf(
    PropTypes.shape({ id: PropTypes.number.isRequired })
  ).isRequired
};

export default AssignmentsList;
