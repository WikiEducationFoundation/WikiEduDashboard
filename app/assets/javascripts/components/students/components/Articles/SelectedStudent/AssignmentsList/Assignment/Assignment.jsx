import React from 'react';
import PropTypes from 'prop-types';

// Components
import CurrentStatus from './CurrentStatus';

export const Assignment = ({ assignment }) => (
  <tr>
    <td>{ assignment.article_title }</td>
    <td>Links</td>
    <td className="current-status">
      <CurrentStatus
        current={assignment.assignment_status}
        statuses={assignment.assignment_all_statuses}
      />
    </td>
  </tr>
);

Assignment.propTypes = {
  assignment: PropTypes.shape({
    article_title: PropTypes.string.isRequired,
    assignment_all_statuses: PropTypes.arrayOf(PropTypes.string).isRequired,
    assignment_status: PropTypes.string.isRequired
  }).isRequired
};

export default Assignment;
