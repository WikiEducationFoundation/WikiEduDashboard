import React from 'react';
import PropTypes from 'prop-types';

import moment from 'moment';

// Helper Functions
const DetailsText = ({ flags }) => (
  <p>
    Last Reviewed:&nbsp;
    <strong>
      {flags.last_reviewed.username}
    </strong>&nbsp;on
    <br />
    <strong>
      {moment(flags.last_reviewed.timestamp).format('LLLL')}
    </strong>
  </p>
);

const NoDetailsText = () => (
  <p>
    This course has not yet been marked as having been reviewed by a staff member.
    Click below to mark it as reviewed!
  </p>
);

export const LastReviewed = ({ course, current_user, persistCourse }) => (
  <div className="module" style={{ textAlign: 'center' }}>
    {
      course.flags && course.flags.last_reviewed && course.flags.last_reviewed.username
      ? <DetailsText flags={course.flags} />
      : <NoDetailsText />
    }
    <button
      className="button"
      onClick={() => {
        course.last_reviewed = {
          username: current_user.username,
          timestamp: moment.utc().format()
        };
        persistCourse(course.slug);
      }}
    >
      Mark as Reviewed
    </button>
  </div>
);

LastReviewed.propTypes = {
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
  persistCourse: PropTypes.func.isRequired
};

export default LastReviewed;
