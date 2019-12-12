import React from 'react';
import PropTypes from 'prop-types';

export const RemoveButton = ({ assignment, unassign, editable }) => {
  let removeButton;
  if (editable) {
    removeButton = <button onClick={() => unassign(assignment)} className="button danger small">Remove</button>;
  } else {
    removeButton = <button onClick={() => unassign(assignment)} className="button danger small" disabled>Remove</button>;
  }

  return (
    <div>
      {removeButton}
    </div>
  );
};

RemoveButton.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  editable: PropTypes.bool,

  // actions
  unassign: PropTypes.func.isRequired,
};

export default RemoveButton;
