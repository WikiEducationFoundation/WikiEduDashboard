import React from 'react';
import PropTypes from 'prop-types';
import GreetStudentsButton from './greet_students_button.jsx';
import { format, toDate, parseISO } from 'date-fns';
import { getUTCDateString } from '../../utils/date_utils.js';
import NotesHandler from '../../components/notes/notes_handler.jsx';

// Helper Functions
const DetailsText = ({ flags }) => (
  <p>
    Last Reviewed:&nbsp;
    <strong>
      {flags.last_reviewed.username}
    </strong>&nbsp;on
    <br />
    <strong>
      {format(toDate(parseISO(flags.last_reviewed.timestamp)), 'PPPP p')}
    </strong>
  </p>
);

const NoDetailsText = () => (
  <p>
    This course has not yet been marked as having been reviewed by a staff member.
    Click below to mark it as reviewed!
  </p>
);

export const AdminQuickActions = ({ course, current_user, persistCourse, greetStudents }) => (
  <div className="module" style={{ textAlign: 'center' }}>
    {current_user.isStaff && (
      <>
        {course.flags && course.flags.last_reviewed && course.flags.last_reviewed.username ? (
          <DetailsText flags={course.flags} />
        ) : (
          <NoDetailsText />
        )}
        <button
          className="button"
          onClick={() => {
            course.last_reviewed = {
              username: current_user.username,
              timestamp: getUTCDateString(),
            };
            persistCourse(course.slug);
          }}
        >
          Mark as Reviewed
        </button>
        <br />
        <br />
        <GreetStudentsButton course={course} current_user={current_user} greetStudents={greetStudents} />
        <br />
      </>
    )}
    {current_user.admin && <div><NotesHandler/></div>}
  </div>
);

AdminQuickActions.propTypes = {
  course: PropTypes.shape({
    flags: PropTypes.shape({
      last_reviewed: PropTypes.shape({
        username: PropTypes.string,
        timestamp: PropTypes.string
      })
    })
  }).isRequired,
  current_user: PropTypes.shape({
    username: PropTypes.string
  }).isRequired,
  persistCourse: PropTypes.func.isRequired,
  greetStudents: PropTypes.func.isRequired

};

export default AdminQuickActions;
