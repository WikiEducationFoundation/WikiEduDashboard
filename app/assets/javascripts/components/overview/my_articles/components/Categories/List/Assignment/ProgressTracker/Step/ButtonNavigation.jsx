import React from 'react';

const update = ({
  assignment, courseSlug,
  updateAssignmentStatus, fetchAssignments
}, undo = false) => async () => {
  const {
    assignment_all_statuses: statuses,
    assignment_status: status
  } = assignment;
  const i = statuses.indexOf(status);
  const updated = (undo ? statuses[i - 1] : statuses[i + 1]) || status;

  await updateAssignmentStatus(assignment, updated);
  await fetchAssignments(courseSlug);
};

export default (props) => {
  const {
    active, index
  } = props;

  return (
    <nav className="step-navigation">
      {
        index ? (
          <button
            className="button small"
            disabled={!active}
            onClick={update(props, 'undo')}
          >
            &laquo; Go Back a Step
          </button>
        ) : null
      }
      <button
        className="button dark small"
        disabled={!active}
        onClick={update(props)}
      >
        Mark Complete &raquo;
      </button>
    </nav>
  );
};
