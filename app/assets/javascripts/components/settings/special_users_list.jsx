import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import SpecialUser from './views/special_user.jsx';

const SpecialUserList = ({ specialUsers, sortBy }) => {
  const users = Object.keys(specialUsers).reduce((acc, position) => {
    const usersByPosition = specialUsers[position].map(user => ({ ...user, position }));
    return acc.concat(usersByPosition);
  }, []);

  const elements = users.map((user, index) => {
    return <SpecialUser
      realname={user.real_name}
      username={user.username}
      position={user.position}
      key={index}
    />;
  });

  const keys = {
    username: {
      label: 'User Name',
      desktop_only: false,
    },
    realname: {
      label: 'Real Name',
      desktop_only: true
    },
    position: {
      label: 'Position',
      desktop_only: true
    },
  };
  return (
    <div>
      <List
        elements={elements}
        keys={keys}
        table_key="special-users"
        none_message={'No Special Users Defined!'}
        sortBy={sortBy}
      />
    </div>
  );
};

SpecialUserList.propTypes = {
  specialUsers: PropTypes.object
};

export default SpecialUserList;
