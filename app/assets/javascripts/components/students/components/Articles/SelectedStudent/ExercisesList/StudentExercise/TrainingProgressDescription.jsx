import React from 'react';
import PropTypes from 'prop-types';

export const TrainingProgressDescription = ({ student }) => {
  const {
    course_training_progress_description: description,
    course_training_progress_assigned_count: training_assigned,
    course_training_progress_completed_count: training_completed
  } = student;

  return description ? (
    <small className={training_assigned === training_completed ? 'modules-complete' : 'red'}>
      {description}
    </small>
  ) : null;
};

TrainingProgressDescription.propTypes = {
  student: PropTypes.shape({
    course_training_progress_description: PropTypes.string,
    course_training_progress_assigned_count: PropTypes.number,
    course_training_progress_completed_count: PropTypes.number
  }).isRequired
};

export default TrainingProgressDescription;
