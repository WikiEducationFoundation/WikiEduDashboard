import React from 'react';
import PropTypes from 'prop-types';

export const BadWorkAlert = ({ alertStatus, submitBadWorkAlert }) => {
  if (alertStatus.created) {
    return (
      <div className="article-alert success">
        <p>Thank you for your submission. We will get back in touch with you as soon as possible.</p>
      </div>
    );
  }
  return (
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
};

BadWorkAlert.propTypes = {
  alertStatus: PropTypes.shape({
    created: PropTypes.bool.isRequired
  }).isRequired,
  submitBadWorkAlert: PropTypes.func.isRequired
};

export default BadWorkAlert;
