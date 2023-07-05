import React from 'react';
import PropTypes from 'prop-types';

import StudentExercise from './StudentExercise/StudentExercise.jsx';
import { useDispatch } from 'react-redux';
import { toggleUI } from '@actions/index.js';

// Helper Functions
const setRealName = (student) => {
  const nameParts = student.real_name.trim().toLowerCase().split(' ');
  student.first_name = nameParts[0];
  student.last_name = nameParts.slice().pop();
};

export const StudentExerciseRow = ({
  assignments, course, current_user, editAssignments,
  openKey, showRecent, student, wikidataLabels,
}) => {
  const dispatch = useDispatch();

  if (student.real_name) setRealName(student);
  const isOpen = openKey === `drawer_${student.id}`;
  return (
    <StudentExercise
      assignments={assignments}
      course={course}
      current_user={current_user}
      editable={editAssignments}
      isOpen={isOpen}
      fullView={false}
      showRecent={showRecent}
      student={student}
      toggleDrawer={key => dispatch(toggleUI(key))}
      wikidataLabels={wikidataLabels}
    />
  );
};

StudentExerciseRow.propTypes = {
  assignments: PropTypes.array,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  editAssignments: PropTypes.bool,
  openKey: PropTypes.string,
  showRecent: PropTypes.bool.isRequired,
  student: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object
};

export default StudentExerciseRow;
