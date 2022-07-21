import React from 'react';
import PropTypes from 'prop-types';
import { capitalize } from 'lodash-es';

// Helper Functions
import { getExerciseStatus, isTrainingDue, orderByDueDate } from '@components/students/utils/trainingHelperFunctions';
import { toDate } from '../../../../../../utils/date_utils';
import { format } from 'date-fns';

// Helper Components
const ExerciseStatusCell = ({ status, sandboxUrl }) => {
  let exerciseLink;
  if (sandboxUrl && status === 'complete') {
    exerciseLink = <> &nbsp; &nbsp; <a className="assignment-links" target="_blank" href={sandboxUrl}>Exercise Sandbox</a></>;
  }

  return <td className={`exercise-status ${status}`}>{capitalize(status)} {exerciseLink}</td>;
};

const generateRow = () => (exercise) => {
  // const dueDate = moment(exercise.due_date).format('MMM Do, YYYY');
  const dueDate = format(toDate(exercise.due_date), 'MMM do, yyyy');
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
