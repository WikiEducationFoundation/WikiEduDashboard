import React from 'react';
import PropTypes from 'prop-types';

export const ExerciseButton = ({
  block_id, course, exercise_url, flags, isComplete, isExercise, slug,
  complete, fetchExercises, incomplete
}) => {
  // An in-app exercise completes itself when the student submits it, so there
  // is nothing to mark manually: show the status instead of the buttons.
  if (exercise_url) {
    return flags?.marked_complete ? <div>Status: Complete!</div> : <span>--</span>;
  }

  let button = (
    <button className="button small left dark" disabled>
      Mark Complete
    </button>
  );

  if (isComplete && isExercise) {
    if (flags.marked_complete) {
      const onClick = () => incomplete(block_id, slug).then(() => fetchExercises(course.id));
      button = (
        <div>
          Status: Complete!
          <button className="button small left" onClick={onClick}>
            Mark Incomplete
          </button>
        </div>
      );
    } else {
      const onClick = () => complete(block_id, slug).then(() => fetchExercises(course.id));
      button = (
        <button className="button small left dark" onClick={onClick}>
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
  exercise_url: PropTypes.string,
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
