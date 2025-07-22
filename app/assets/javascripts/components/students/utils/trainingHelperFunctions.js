import { Date } from 'core-js';
import { toDate } from '../../../utils/date_utils';
import { isBefore } from 'date-fns';
// This function returns the status of exercise
// returns status as unread/complete/incomplete depending on the deadline status and flags if any
export const getExerciseStatus = (exercise) => {
  const isComplete = exercise.deadline_status === 'complete';
  const flags = exercise.flags || {};
  let status = '';
  if (isComplete && flags.marked_complete) {
    status = 'complete';
  } else if (isComplete) {
    status = 'incomplete';
  } else {
    status = 'unread';
  }
  return status;
};

// This function compares training's due date with current date
// returns true if the current date has not passed the training's due date
export const isTrainingDue = (date) => {
  const currentDate = new Date();
  const trainingDueDate = new Date(Date.parse(date.replace(/-/g, ' ')));
  return trainingDueDate >= currentDate;
};

// This is a sorting function that returns the earlier training of the two inputs
export const orderByDueDate = (a, b) => (isBefore(toDate(a.due_date), toDate(b.due_date)) ? -1 : 1);
