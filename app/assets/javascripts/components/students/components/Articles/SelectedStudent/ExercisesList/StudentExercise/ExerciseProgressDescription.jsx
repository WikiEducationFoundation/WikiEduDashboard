import React from 'react';
import PropTypes from 'prop-types';

export const ExerciseProgressDescription = ({ student }) => {
  const {
    course_exercise_progress_description: description,
    course_exercise_progress_assigned_count: exercise_assigned,
    course_exercise_progress_completed_count: exercise_completed,
  } = student;

  const classHighlight = exercise_assigned === exercise_completed ? 'modules-complete' : 'red';
  return description ? (
    <span className={`completeness ${classHighlight}`}>
      {description}
    </span>
  ) : null;
};

ExerciseProgressDescription.propTypes = {
  student: PropTypes.shape({
    course_exercise_progress_description: PropTypes.string,
    course_exercise_progress_assigned_count: PropTypes.number,
    course_exercise_progress_completed_count: PropTypes.number
  }).isRequired
};

export default ExerciseProgressDescription;
