import React from 'react';
import PropTypes from 'prop-types';
import EnrollButton from '../students/enroll_button.jsx';

const InlineUsers = (props) => {
  const lastUserIndex = props.users.length - 1;
  let userList = props.users.map((user, index) => {
    let extraInfo = '';
    const link = `/users/${user.username}`; // User profile page
    if (user.real_name) {
      const email = user.email ? ` / ${user.email}` : '';
      const roleDescription = user.role_description ? ` — ${user.role_description}` : '';
      extraInfo = ` (${user.real_name}${email}${roleDescription})`;
    }

    if (index !== lastUserIndex) {
      extraInfo = `${extraInfo}, `;
    }

    return (
      <span key={user.username}>
        <a href={link}>{user.username}</a>
        {extraInfo}
      </span>
    );
  });

  userList = userList.length > 0 ? userList : I18n.t('courses.none');

  let inlineList;
  if (props.users.length > 0 || props.editable) {
    inlineList = <span><strong>{props.title}:</strong> {userList}</span>;
  }

  const allowed = props.role !== 4 || (props.current_user.role === 4 || props.current_user.admin);
  const button = (
    <EnrollButton
      {...props}
      users={props.users}
      role={props.role}
      inline={true}
      allowed={allowed}
      show={props.editable && allowed}
    />
  );

  return <div>{inlineList}{button}</div>;
};

InlineUsers.propTypes = {
  title: PropTypes.string,
  role: PropTypes.number,
  course: PropTypes.object,
  users: PropTypes.array,
  current_user: PropTypes.object,
  editable: PropTypes.bool
};

export default InlineUsers;
