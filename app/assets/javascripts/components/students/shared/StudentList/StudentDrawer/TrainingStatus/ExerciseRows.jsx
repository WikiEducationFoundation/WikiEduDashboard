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

const generateRow = () => (exercise) => {
  const dueDate = moment(exercise.due_date).format('MMM Do, YYYY');
  const isComplete = exercise.deadline_status === 'complete';
  const flags = exercise.flags || {};
  let exercise_status = '';
  if (isComplete && flags.marked_complete) {
    exercise_status = 'complete';
  } else if (isComplete) {
    exercise_status = 'incomplete';
  } else {
    exercise_status = 'unread';
  }
  return (
    <tr className={exercise.overdue ? 'student-training-module overdue' : 'student-training-module'} key={exercise.id}>
      <td>{exercise.name} <small>Due by {dueDate}</small></td>
      <ExerciseStatusCell status={exercise_status} sandboxUrl={exercise.sandbox_url}/>
    </tr>
  );
};

export const ExerciseRows = ({ exercises }) => {
  const { unread, incomplete, complete } = exercises;
  const all_exercises = [...unread, ...incomplete, ...complete];
  return [
    all_exercises.sort(orderByDueDate).map(generateRow()),
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
