import React from 'react';
import PropTypes from 'prop-types';

export const Tooltip = ({ message, text }) => (
  <div className="tooltip-trigger">
    <small className="peer-review-count">{ text }</small>
    <div className="tooltip dark">
      <p>{ message }</p>
    </div>
  </div>
);

Tooltip.propTypes = {
  // props
  message: PropTypes.string.isRequired,
  text: PropTypes.string.isRequired,
};

export default Tooltip;
