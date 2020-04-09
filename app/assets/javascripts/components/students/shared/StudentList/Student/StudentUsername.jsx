import React from 'react';
import PropTypes from 'prop-types';

// Utility Functions
import { trunc } from '~/app/assets/javascripts/utils/strings';

// Constants
const STUDENT_ROLE = 0;

export const StudentUsername = ({ current_user, student }) => {
  const username = trunc(student.username);
  const showRealName = student.real_name // Student has a real name listed
    && current_user // The current user exists
    && (current_user.admin || current_user.role > STUDENT_ROLE); // Current user is advanced role

  return showRealName ? (
    <span>
      <strong>{trunc(student.real_name)}</strong>&nbsp;
      (<a onClick={e => e.preventDefault()}>{username}</a>)
    </span>
  ) : (
    <span><a onClick={e => e.preventDefault()}>{username}</a></span>
  );
};

StudentUsername.propTypes = {
  current_user: PropTypes.shape({
    admin: PropTypes.any,
    role: PropTypes.number.isRequired
  }),
  student: PropTypes.shape({
    real_name: PropTypes.string,
    username: PropTypes.string.isRequired
  }).isRequired
};

export default StudentUsername;
