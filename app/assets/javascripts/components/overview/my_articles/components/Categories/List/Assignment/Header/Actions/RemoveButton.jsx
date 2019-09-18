import React from 'react';

export default ({ assignment, unassign }) => (
  <div>
    <button
      onClick={() => unassign(assignment)}
      className="button danger small"
    >
      Remove
    </button>
  </div>
);
