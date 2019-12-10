import React from 'react';
import PropTypes from 'prop-types';

import Student from '@components/students/student.jsx';

// Helper Functions
const setRealName = (student) => {
  const nameParts = student.real_name.trim().toLowerCase().split(' ');
  student.first_name = nameParts[0];
  student.last_name = nameParts.slice().pop();
};

export const StudentRow = ({
  assignments, course, current_user, editAssignments,
  openKey, showRecent, student, toggleUI, wikidataLabels
}) => {
  const toggleDrawer = toggleUI;
  if (student.real_name) setRealName(student);
  const isOpen = openKey === `drawer_${student.id}`;
  return (
    <Student
      student={student}
      course={course}
      current_user={current_user}
      editable={editAssignments}
      assignments={assignments}
      isOpen={isOpen}
      toggleDrawer={toggleDrawer}
      wikidataLabels={wikidataLabels}
      showRecent={showRecent}
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
  toggleUI: PropTypes.func.isRequired,
  wikidataLabels: PropTypes.object
};

export default StudentRow;
