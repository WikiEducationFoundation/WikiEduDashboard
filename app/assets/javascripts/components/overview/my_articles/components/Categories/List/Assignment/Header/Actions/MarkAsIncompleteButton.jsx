import React from 'react';
import PropTypes from 'prop-types';

const update = ({
  assignment, courseSlug,
  handleUpdateAssignment, refreshAssignments
}) => async () => {
  const statuses = assignment.assignment_all_statuses;
  const prev = statuses[statuses.length - 2];

  await handleUpdateAssignment(assignment, prev);
  await refreshAssignments(courseSlug);
};

export const MarkAsIncompleteButton = props => (
  <div>
    <button
      className="button danger small"
      onClick={update(props)}
    >
      Mark as Incomplete
    </button>
  </div>
);

MarkAsIncompleteButton.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  courseSlug: PropTypes.string.isRequired,

  // actions
  handleUpdateAssignment: PropTypes.func.isRequired,
  refreshAssignments: PropTypes.func.isRequired,
};

export default MarkAsIncompleteButton;
