import React from 'react';
import PropTypes from 'prop-types';
import { capitalize } from 'lodash-es';
import moment from 'moment';

// Helper Components
const ExerciseStatusCell = ({ status, sandboxUrl }) => {
  let exerciseLink;
  if (sandboxUrl && status === 'complete') {
    exerciseLink = <> &nbsp; &nbsp; <a className="assignment-links" target="_blank" href={sandboxUrl}>Exercise Sandbox</a></>;
  }

  return <td className={`exercise-status ${status}`}>{capitalize(status)} {exerciseLink}</td>;
};

// Helper Functions
const orderByDueDate = (a, b) => (moment(a.due_date).isBefore(b.due_date) ? -1 : 1);

// This function returns the status of exercise
// returns status as unread/complete/incomplete depending on the deadline status and flags if any
const getExerciseStatus = (exercise) => {
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

// This function compares exercise's due date with current date
// returns true if the current date has not passed the training's due date
const isExerciseDue = (exercise) => {
  const currentDate = new Date();
  const exerciseDueDate = new Date(Date.parse(exercise.due_date.replace(/-/g, ' ')));
  return exerciseDueDate >= currentDate;
};

const generateRow = () => (exercise) => {
  const dueDate = moment(exercise.due_date).format('MMM Do, YYYY');
  const exerciseStatus = getExerciseStatus(exercise);
  return (
    <tr className={isExerciseDue(exercise) ? 'student-training-module due-training' : 'student-training-module'} key={exercise.id}>
      <td>{exercise.name} <small>Due by {dueDate}</small></td>
      <ExerciseStatusCell status={exerciseStatus} sandboxUrl={exercise.sandbox_url}/>
    </tr>
  );
};

export const ExerciseRows = ({ exercises }) => {
  const { unread, incomplete, complete } = exercises;
  const allExercises = [...unread, ...incomplete, ...complete];
  return [
    allExercises.sort(orderByDueDate).map(generateRow()),
  ];
};

const exerciseShape = PropTypes.shape({
  id: PropTypes.number.isRequired,
  due_date: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired
});
ExerciseRows.propTypes = {
  exercises: PropTypes.shape({
    unread: PropTypes.arrayOf(exerciseShape),
    incomplete: PropTypes.arrayOf(exerciseShape),
    complete: PropTypes.arrayOf(exerciseShape)
  }).isRequired
};

export default ExerciseRows;
