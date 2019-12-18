import React from 'react';
import PropTypes from 'prop-types';

// Components
import AssignmentsList from './AssignmentsList/AssignmentsList.jsx';

const ASSIGNMENT_ROLE = 0;
const REVIEWING_ROLE = 1;

export const SelectedStudent = ({ assignments }) => {
  const { assigned, reviewing } = assignments.reduce((acc, assignment) => {
    if (ASSIGNMENT_ROLE === assignment.role) acc.assigned.push(assignment);
    if (REVIEWING_ROLE === assignment.role) acc.reviewing.push(assignment);
    return acc;
  }, { assigned: [], reviewing: [] });

  return (
    <article className="assignments-list">
      {
        !!assigned.length && <AssignmentsList
          assignments={assigned}
          title="Assigned Articles"
        />
      }

      {
        !!reviewing.length && <AssignmentsList
          assignments={reviewing}
          title="Reviewing Articles"
        />
      }
    </article>
  );
};

SelectedStudent.propTypes = {
  assignments: PropTypes.array.isRequired,
  student: PropTypes.object.isRequired,
};

export default SelectedStudent;
