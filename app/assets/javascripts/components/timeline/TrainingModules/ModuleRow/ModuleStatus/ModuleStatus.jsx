import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import {
  DISCUSSION_KIND, EXERCISE_KIND, TRAINING_MODULE_KIND
} from '~/app/assets/javascripts/constants';

// Components
import ExerciseButton from './ExerciseButton';

// Actions
import {
  setExerciseModuleComplete, setExerciseModuleIncomplete
} from '~/app/assets/javascripts/actions/training_actions';
import {
  fetchTrainingModuleExercisesByUser
} from '~/app/assets/javascripts/actions/exercises_actions';

export const ModuleStatus = ({
  block_id, course, deadline_status, due_date, flags, kind, module_progress, progressClass, slug,
  complete, fetchExercises, incomplete
}) => {
  const isTrainingModule = kind === TRAINING_MODULE_KIND;
  const isExercise = kind === EXERCISE_KIND;
  const isOverdue = deadline_status === 'overdue';
  const isComplete = deadline_status === 'complete';

  // Display current information about the training module
  if (isTrainingModule || isExercise) {
    const button = (
      <ExerciseButton
        block_id={block_id}
        course={course}
        flags={flags}
        isComplete={isComplete}
        isExercise={isExercise}
        slug={slug}
        complete={complete}
        fetchExercises={fetchExercises}
        incomplete={incomplete}
      />
    );
    const progress = module_progress || '--';
    return (
      <td className={progressClass}>
        { isTrainingModule ? progress : button }
        { isOverdue ? ` (due on ${due_date})` : null }
      </td>
    );
  }

  return null;
};

ModuleStatus.propTypes = {
  block_id: PropTypes.number.isRequired,
  course: PropTypes.shape({
    id: PropTypes.number.isRequired
  }).isRequired,
  deadline_status: PropTypes.string,
  due_date: PropTypes.string.isRequired,
  flags: PropTypes.object,
  kind: PropTypes.oneOf([
    DISCUSSION_KIND, EXERCISE_KIND, TRAINING_MODULE_KIND
  ]),
  module_progress: PropTypes.string,
  progressClass: PropTypes.string.isRequired,
  slug: PropTypes.string.isRequired,

  complete: PropTypes.func.isRequired,
  incomplete: PropTypes.func.isRequired,
};

const mapStateToProps = state => ({
  course: state.course
});

const mapDispatchToProps = {
  complete: setExerciseModuleComplete,
  incomplete: setExerciseModuleIncomplete,
  fetchExercises: fetchTrainingModuleExercisesByUser
};

export default connect(mapStateToProps, mapDispatchToProps)(ModuleStatus);
