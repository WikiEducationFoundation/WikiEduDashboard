import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import AdminUser from './containers/admin_user_container.jsx';

const AdminUserList = ({ adminUsers, sortBy }) => {
  const elements = adminUsers.map((user) => {
    return <AdminUser user={user} key={user.id} />;
  });

  const keys = {

    username: {
      label: 'User Name',
      desktop_only: false,
    },
    real_name: {
      label: 'Real Name',
      desktop_only: true
    },
    admin_level: {
      label: 'Admin Level',
      desktop_only: false
    },
  };

  return (
    <div>
      <List
        elements={elements}
        keys={keys}
        table_key="admin-users"
        none_message={'no admin users'}
        sortBy={sortBy}
      />
    </div>
  );
};

AdminUserList.propTypes = {
  adminUsers: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number,
      username: PropTypes.string.isRequired,
      real_name: PropTypes.string,
      permissions: PropTypes.number.isRequired,
    })
  ),
};

export default AdminUserList;
