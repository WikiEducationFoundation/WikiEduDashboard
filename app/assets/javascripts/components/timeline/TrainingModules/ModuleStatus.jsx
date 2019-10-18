import React from 'react';
import { connect } from 'react-redux';
import {
  EXERCISE_KIND, TRAINING_MODULE_KIND
} from '../../../constants/timeline';

// Actions
import {
  setExerciseModuleComplete, setExerciseModuleIncomplete
} from '../../../actions/training_actions';

export const ModuleStatus = ({
  block_id, deadline_status, due_date, flags, kind, module_progress, slug,
  complete, incomplete
}) => {
  const isTrainingModule = kind === TRAINING_MODULE_KIND;
  const isExercise = kind === EXERCISE_KIND;
  const isOverdue = deadline_status === 'overdue';
  const isComplete = deadline_status === 'complete';


  let nonTrainingProgress = null;
  if (isComplete && isExercise && Features.enableAdvancedFeatures) {
    if (flags.marked_complete) {
      nonTrainingProgress = (
        <button className="button small left" onClick={() => incomplete(block_id, slug)}>
          Mark Incomplete
        </button>
      );
    } else {
      nonTrainingProgress = (
        <button className="button small left dark" onClick={() => complete(block_id, slug)}>
          Mark Complete
        </button>
      );
    }
  }

  // Display current information about the training module
  if (module_progress && deadline_status) {
    return (
      <div>
        {
          isTrainingModule ? module_progress : nonTrainingProgress
        }
        {isOverdue ? ` (due on ${due_date})` : null}
      </div>
    );
  }

  // If it's a training module, show the placeholder
  return isTrainingModule ? '--' : null;
};

const mapDispatchToProps = {
  complete: setExerciseModuleComplete,
  incomplete: setExerciseModuleIncomplete
};

export default connect(null, mapDispatchToProps)(ModuleStatus);
