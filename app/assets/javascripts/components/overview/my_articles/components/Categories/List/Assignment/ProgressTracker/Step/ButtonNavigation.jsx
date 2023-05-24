import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { updateAssignmentStatus, fetchAssignments } from '@actions/assignment_actions';

const update = ({
  assignment, course,
  stepAction, dispatch
}, undo = false) => async () => {
  const {
    assignment_all_statuses: statuses,
    assignment_status: status
  } = assignment;
  const i = statuses.indexOf(status);
  const updated = (undo ? statuses[i - 1] : statuses[i + 1]) || status;
  await dispatch(updateAssignmentStatus(assignment, updated));
  await dispatch(fetchAssignments(course.slug));
  if (stepAction) {
    await stepAction({ assignment, course })(dispatch);
  }
};

export const ButtonNavigation = (props) => {
  const dispatch = useDispatch();

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
            onClick={update({ ...props, dispatch }, 'undo')}
          >
            &laquo; Go Back a Step
          </button>
        ) : null
      }
      <button
        className="button dark small"
        disabled={!active}
        onClick={update({ ...props, dispatch })}
      >
        {buttonLabel || 'Mark Complete'} &raquo;
      </button>
    </nav>
  );
};

ButtonNavigation.propTypes = {
  active: PropTypes.bool.isRequired,
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
};

export default ButtonNavigation;
