import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import SpecialUser from './views/special_user.jsx';

const SpecialUserList = ({ specialUsers, sortBy }) => {
  const elements = Object.keys(specialUsers).map((position, index) => {
    const user = specialUsers[position];
    return <SpecialUser
      realname={user.real_name}
      username={user.username}
      position={position}
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
