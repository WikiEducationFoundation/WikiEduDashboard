import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import { capitalize } from 'lodash-es';

// Helper Functions
import { getExerciseStatus, isTrainingDue, orderByDueDate } from '@components/students/utils/trainingHelperFunctions';
import { getCurrentUser } from '~/app/assets/javascripts/selectors';
import { toDate } from '../../../../../../utils/date_utils';
import { format } from 'date-fns';

// Helper Components
import ResponsePopover from '@components/claim_verification_exercise/ResponsePopover.jsx';

const ExerciseStatusCell = ({ status, sandboxUrl, responsePopover }) => {
  let exerciseLink;
  if (sandboxUrl && status === 'complete') {
    exerciseLink = <> &nbsp; &nbsp; <a className="assignment-links" target="_blank" href={sandboxUrl}>Exercise Sandbox</a></>;
  }

  return (
    <td className={`exercise-status ${status}`}>
      {capitalize(status)} {exerciseLink}
      {responsePopover && <> &nbsp; &nbsp; {responsePopover}</>}
    </td>
  );
};

const generateRow = popoverFor => (exercise) => {
  const dueDate = format(toDate(exercise.due_date), 'MMM do, yyyy');
  const exerciseStatus = getExerciseStatus(exercise);
  return (
    <tr className={exercise.due_date && isTrainingDue(exercise.due_date) ? 'student-training-module due-training' : 'student-training-module'} key={exercise.id}>
      <td>{exercise.name} <small>Due by {dueDate}</small></td>
      <ExerciseStatusCell
        status={exerciseStatus}
        sandboxUrl={exercise.sandbox_url}
        responsePopover={popoverFor(exercise, exerciseStatus)}
      />
    </tr>
  );
};

export const ExerciseRows = ({ exercises, student }) => {
  const currentUser = useSelector(getCurrentUser);
  const isStaff = Boolean(currentUser?.isAdvancedRole);
  const isSelf = student?.id != null && currentUser?.id === student.id;

  // The in-app-exercise counterpart of the sandbox link: a popover with the
  // student's submitted answers, shown in place. Staff can see any student's;
  // a student can see their own (the endpoint scopes to the viewer).
  const popoverFor = (exercise, status) => {
    if (!(isStaff || isSelf) || !exercise.exercise_url || status !== 'complete') { return null; }
    return <ResponsePopover student={student} />;
  };

  const { unread, incomplete, complete } = exercises;
  const allExercises = [...unread, ...incomplete, ...complete];
  return [
    allExercises.sort(orderByDueDate).map(generateRow(popoverFor)),
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
  }).isRequired,
  // The student whose drawer this is.
  student: PropTypes.object
};

export default ExerciseRows;
