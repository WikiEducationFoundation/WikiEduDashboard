import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { updateAssignmentStatus, fetchAssignments } from '../../../../../../../../../actions/assignment_actions';

const update = ({ assignment, courseSlug, dispatch }) => async () => {
  const statuses = assignment.assignment_all_statuses;
  const prev = statuses[statuses.length - 2];

  await dispatch(updateAssignmentStatus(assignment, prev));
  await dispatch(fetchAssignments(courseSlug));
};

export const MarkAsIncompleteButton = (props) => {
  const dispatch = useDispatch();
  return (
    <div>
      <button
        className="button danger small"
        onClick={update({ ...props, dispatch })}
      >
        Mark as Incomplete
      </button>
    </div>
  );
};

MarkAsIncompleteButton.propTypes = {
  assignment: PropTypes.object.isRequired,
  courseSlug: PropTypes.string.isRequired,
};

export default MarkAsIncompleteButton;
