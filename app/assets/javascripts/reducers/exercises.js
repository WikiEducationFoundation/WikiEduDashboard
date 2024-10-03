import {
  EXERCISE_FETCH_STARTED,
  EXERCISE_FETCH_COMPLETED,

  EXERCISE_KIND
} from '../constants';

const initialState = {
  complete: [],
  incomplete: [],
  unread: [],

  loading: true
};

const categorizeExercises = (blocks = []) => {
  const trainings = blocks.reduce((acc, block) => acc.concat(block.training_modules), [])
    .filter(val => val);
  return trainings.reduce((acc, training) => {
    if (training.kind !== EXERCISE_KIND) return acc;

    const isComplete = training.deadline_status === 'complete';
    const flags = training.flags || {};
    if (isComplete && flags.marked_complete) {
      acc.complete.push(training);
    } else if (isComplete) {
      acc.incomplete.push(training);
    } else {
      acc.unread.push(training);
    }

    acc.count += 1;
    return acc;
  }, { complete: [], incomplete: [], unread: [], count: 0 });
};

export default function exercises(state = initialState, action) {
  switch (action.type) {
    case EXERCISE_FETCH_STARTED:
      return { ...state, loading: true };
    case EXERCISE_FETCH_COMPLETED:
      return { ...state, ...categorizeExercises(action.data.blocks), loading: false };
    default:
      return state;
  }
}
