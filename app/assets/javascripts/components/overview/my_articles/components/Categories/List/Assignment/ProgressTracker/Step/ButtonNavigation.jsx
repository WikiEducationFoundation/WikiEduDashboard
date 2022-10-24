import React from 'react';
import PropTypes from 'prop-types';

const update = ({
  assignment, courseSlug,
  updateAssignmentStatus, fetchAssignments, stepAction
}, undo = false) => async () => {
  const {
    assignment_all_statuses: statuses,
    assignment_status: status
  } = assignment;
  const i = statuses.indexOf(status);
  const updated = (undo ? statuses[i - 1] : statuses[i + 1]) || status;

  await updateAssignmentStatus(assignment, updated);
  await fetchAssignments(courseSlug);
  if (stepAction) {
    await stepAction();
  }
};

export const ButtonNavigation = (props) => {
  const {
    active, index, buttonLabel
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
        {buttonLabel || 'Mark Complete'} &raquo;
      </button>
    </nav>
  );
};

ButtonNavigation.propTypes = {
  // props
  active: PropTypes.bool.isRequired,
  assignment: PropTypes.object.isRequired,
  courseSlug: PropTypes.string.isRequired,
  index: PropTypes.number.isRequired,
  // actions
  updateAssignmentStatus: PropTypes.func.isRequired,
  fetchAssignments: PropTypes.func.isRequired,
};

export default ButtonNavigation;
