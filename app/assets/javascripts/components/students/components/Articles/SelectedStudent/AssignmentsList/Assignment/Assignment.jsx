import React from 'react';
import PropTypes from 'prop-types';

// Components
import CurrentStatus from './CurrentStatus';
import AssignmentLinks from '@components/common/AssignmentLinks/AssignmentLinks.jsx';

export const Assignment = ({ assignment, courseType, user }) => (
  <tr>
    <td>{ assignment.article_title }</td>
    <td>
      <AssignmentLinks
        assignment={assignment}
        courseType={courseType}
        user={user}
      />
    </td>
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
  }).isRequired,
  courseType: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired
};

export default Assignment;
