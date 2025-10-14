import React from 'react';
import PropTypes from 'prop-types';

export const ExerciseButton = ({
  block_id, course, flags, isComplete, isExercise, slug,
  complete, fetchExercises, incomplete
}) => {
  let button = (
    <button type="button" className="button small left dark" disabled>
      Mark Complete
    </button>
  );

  if (isComplete && isExercise) {
    if (flags.marked_complete) {
      const onClick = () => incomplete(block_id, slug).then(() => fetchExercises(course.id));
      button = (
        <div>
          Status: Complete!
          <button type="button" className="button small left" onClick={onClick}>
            Mark Incomplete
          </button>
        </div>
      );
    } else {
      const onClick = () => complete(block_id, slug).then(() => fetchExercises(course.id));
      button = (
        <button type="button" className="button small left dark" onClick={onClick}>
          Mark Complete
        </button>
      );
    }
  }

  return button;
};

ExerciseButton.propTypes = {
  block_id: PropTypes.number.isRequired,
  course: PropTypes.shape({
    id: PropTypes.number.isRequired
  }).isRequired,
  flags: PropTypes.shape({
    marked_complete: PropTypes.bool
  }),
  isComplete: PropTypes.bool.isRequired,
  isExercise: PropTypes.bool.isRequired,
  slug: PropTypes.string.isRequired,

  complete: PropTypes.func.isRequired,
  incomplete: PropTypes.func.isRequired,
};

export default ExerciseButton;
