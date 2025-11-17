import React from 'react';
import PropTypes from 'prop-types';

const TrackingDescription = ({ trackingDescription }) => {
  if (!trackingDescription) return null;

  return (
    <div className="overview__tracking-description">
      <p>{trackingDescription}</p>
    </div>
  );
};

TrackingDescription.propTypes = {
  trackingDescription: PropTypes.string
};

export default TrackingDescription;
