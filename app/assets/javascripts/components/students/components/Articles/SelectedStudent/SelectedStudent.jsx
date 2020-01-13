import React from 'react';
import PropTypes from 'prop-types';

// Components
import Header from './Header.jsx';
import AssignmentsList from './AssignmentsList/AssignmentsList.jsx';
import NoAssignments from './NoAssignments.jsx';

// Utils
import { processAssignments } from '@components/overview/my_articles/utils/processAssignments';

export const SelectedStudent = ({
  assignments, course, current_user, selected, wikidataLabels
}) => {
  const {
    assigned, reviewing
  } = processAssignments({ assignments, course, current_user: selected });

  return (
    <article className="assignments-list">
      <Header
        assignments={assignments}
        course={course}
        current_user={current_user}
        reviewing={reviewing}
        selected={selected}
        wikidataLabels={wikidataLabels}
      />

      {
        !!assigned.length && <AssignmentsList
          assignments={assigned}
          course={course}
          title="Assigned Articles"
          user={selected}
        />
      }

      {
        !!reviewing.length && <AssignmentsList
          assignments={reviewing}
          course={course}
          title="Reviewing Articles"
          user={selected}
        />
      }

      {
        !assigned.length && !reviewing.length && <NoAssignments />
      }
    </article>
  );
};

SelectedStudent.propTypes = {
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  selected: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object
};

export default SelectedStudent;
