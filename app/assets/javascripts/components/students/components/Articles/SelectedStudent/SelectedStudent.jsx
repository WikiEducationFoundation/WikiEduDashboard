import React from 'react';
import PropTypes from 'prop-types';

// Components
import Header from './Header.jsx';
import AssignmentsList from './AssignmentsList/AssignmentsList.jsx';
import NoAssignments from './NoAssignments.jsx';

import {
  ASSIGNED_ROLE, REVIEWING_ROLE
} from '~/app/assets/javascripts/constants/assignments';

export const SelectedStudent = ({
  allAssignments, assignments, course, current_user, selected, wikidataLabels
}) => {
  const { assigned, reviewing } = assignments.reduce((acc, assignment) => {
    if (ASSIGNED_ROLE === assignment.role) acc.assigned.push(assignment);
    if (REVIEWING_ROLE === assignment.role) acc.reviewing.push(assignment);
    return acc;
  }, { assigned: [], reviewing: [] });

  return (
    <article className="assignments-list">
      <Header
        assignments={allAssignments}
        course={course}
        current_user={current_user}
        reviewing={reviewing}
        selected={selected}
        wikidataLabels={wikidataLabels}
      />

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

      {
        !assigned.length && !reviewing.length && <NoAssignments />
      }
    </article>
  );
};

SelectedStudent.propTypes = {
  allAssignments: PropTypes.array.isRequired,
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  selected: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object
};

export default SelectedStudent;
