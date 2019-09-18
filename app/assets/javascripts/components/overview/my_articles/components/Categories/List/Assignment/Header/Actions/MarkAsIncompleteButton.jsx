import React from 'react';

const update = ({
  assignment, courseSlug,
  handleUpdateAssignment, refreshAssignments
}) => async () => {
  const statuses = assignment.assignment_all_statuses;
  const prev = statuses[statuses.length - 2];

  await handleUpdateAssignment(assignment, prev);
  await refreshAssignments(courseSlug);
};

export default props => (
  <div>
    <button
      className="button danger small"
      onClick={update(props)}
    >
      Mark as Incomplete
    </button>
  </div>
);
