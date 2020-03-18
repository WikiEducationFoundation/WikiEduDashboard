import React from 'react';
import PropTypes from 'prop-types';

export const BadWorkAlert = ({ submitBadWorkAlert }) => (
  <div className="article-alert">
    <p>Click this button if you believe the work completed by your students needs intervention by a staff member of Wiki Education Foundation. A member of our staff will get in touch with you and your students.</p>
    <button
      className="button danger"
      onClick={() => submitBadWorkAlert()}
    >
      Notify Wiki Expert
    </button>
  </div>
);

BadWorkAlert.propTypes = {
  submitBadWorkAlert: PropTypes.func.isRequired
};

export default BadWorkAlert;
