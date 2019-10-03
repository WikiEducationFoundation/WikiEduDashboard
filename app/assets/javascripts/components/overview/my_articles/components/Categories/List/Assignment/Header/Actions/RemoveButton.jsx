import React from 'react';
import PropTypes from 'prop-types';

export const RemoveButton = ({ assignment, unassign }) => (
  <div>
    <button
      onClick={() => unassign(assignment)}
      className="button danger small"
    >
      Remove
    </button>
  </div>
);

RemoveButton.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,

  // actions
  unassign: PropTypes.func.isRequired,
};

export default RemoveButton;
