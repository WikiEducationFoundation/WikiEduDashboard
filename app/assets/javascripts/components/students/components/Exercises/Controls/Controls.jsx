import React from 'react';
import PropTypes from 'prop-types';

// Components
import SortButton from '@components/students/shared/SortButton.jsx';

export const Controls = (props) => {
  const {
    current_user, sortSelect
  } = props;

  return (
    <div className="users-control">
      <SortButton
        current_user={current_user}
        sortSelect={sortSelect}
      />
    </div>
  );
};

Controls.propTypes = {
  current_user: PropTypes.object.isRequired,
  sortSelect: PropTypes.func.isRequired
};

export default Controls;
