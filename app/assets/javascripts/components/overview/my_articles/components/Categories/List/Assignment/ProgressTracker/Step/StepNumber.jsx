import React from 'react';
import PropTypes from 'prop-types';

export const StepNumber = ({ index }) => (
  <span className="step-number">{index + 1}</span>
);

StepNumber.propTypes = {
  // props
  index: PropTypes.number.isRequired,
};

export default StepNumber;
