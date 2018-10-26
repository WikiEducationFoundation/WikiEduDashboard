import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import SpecialUser from './containers/special_user_container.jsx';

const SpecialUserList = ({ specialUsers, sortBy }) => {
  const elements = Object.keys(specialUsers).map((position, index) => {
    const username = specialUsers[position];
    return <SpecialUser username={username} position={position} key={index} />;
  });

  const keys = {
    position: {
      label: 'Position',
      desktop_only: true
    },
    username: {
      label: 'User Name',
      desktop_only: false,
    }
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
