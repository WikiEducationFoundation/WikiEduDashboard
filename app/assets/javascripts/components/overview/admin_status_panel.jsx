import React from 'react';
import PropTypes from 'prop-types';

const AdminStatusPanel = ({ course }) => {
  const statuses = [];
  if (course.flags.no_sandboxes) {
    statuses.push('No Sandboxes');
  }
  if (statuses.length === 0) { return null; }

  return (
    <div className="admin-status-panel" >
      {statuses[0]}
    </div >
  );
};

AdminStatusPanel.propTypes = {
  course: PropTypes.object
};

export default AdminStatusPanel;
