import React from 'react';
import PropTypes from 'prop-types';
import { capitalize } from 'lodash-es';
import moment from 'moment';

// Helper Functions
import { getExerciseStatus, isTrainingDue, orderByDueDate } from '@components/students/utils/trainingHelperFunctions';

// Helper Components
const ExerciseStatusCell = ({ status, sandboxUrl }) => {
  let exerciseLink;
  if (sandboxUrl && status === 'complete') {
    exerciseLink = <> &nbsp; &nbsp; <a className="assignment-links" target="_blank" href={sandboxUrl}>Exercise Sandbox</a></>;
  }

  return <td className={`exercise-status ${status}`}>{capitalize(status)} {exerciseLink}</td>;
};

const generateRow = () => (exercise) => {
  const dueDate = moment(exercise.due_date).format('MMM Do, YYYY');
  const exerciseStatus = getExerciseStatus(exercise);
  return (
    <tr className={exercise.due_date && isTrainingDue(exercise.due_date) ? 'student-training-module due-training' : 'student-training-module'} key={exercise.id}>
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
