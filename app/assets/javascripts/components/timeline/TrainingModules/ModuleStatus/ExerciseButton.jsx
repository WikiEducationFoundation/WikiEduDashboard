import React from 'react';
import PropTypes from 'prop-types';

export const ExerciseButton = ({
  block_id, flags, isComplete, isExercise, slug,
  complete, incomplete
}) => {
  if (!Features.enableAdvancedFeatures) return null;
  let button = (
    <button className="button small left dark" disabled>
      Mark Complete
    </button>
  );

  if (isComplete && isExercise) {
    if (flags.marked_complete) {
      button = (
        <button className="button small left" onClick={() => incomplete(block_id, slug)}>
          Mark Incomplete
        </button>
      );
    } else {
      button = (
        <button className="button small left dark" onClick={() => complete(block_id, slug)}>
          Mark Complete
        </button>
      );
    }
  }

  return button;
};

ExerciseButton.propTypes = {
  block_id: PropTypes.number.isRequired,
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
