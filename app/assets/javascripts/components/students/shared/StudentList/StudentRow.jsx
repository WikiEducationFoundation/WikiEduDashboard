import React from 'react';
import PropTypes from 'prop-types';

import Student from './Student/Student.jsx';

// Helper Functions
const setRealName = (student) => {
  const nameParts = student.real_name.trim().toLowerCase().split(' ');
  student.first_name = nameParts[0];
  student.last_name = nameParts.slice().pop();
};

export const StudentRow = ({
  assignments, course, current_user, editAssignments, showRecent, student, wikidataLabels
}) => {
  if (student.real_name) setRealName(student);
  return (
    <Student
      assignments={assignments}
      course={course}
      current_user={current_user}
      editable={editAssignments}
      showRecent={showRecent}
      student={student}
      wikidataLabels={wikidataLabels}
    />
  );
};

StudentRow.propTypes = {
  assignments: PropTypes.array,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  editAssignments: PropTypes.bool,
  openKey: PropTypes.string,
  showRecent: PropTypes.bool.isRequired,
  student: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object
};

export default StudentRow;
