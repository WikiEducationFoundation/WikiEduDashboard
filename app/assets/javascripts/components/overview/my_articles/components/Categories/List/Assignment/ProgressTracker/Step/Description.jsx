import React from 'react';
import PropTypes from 'prop-types';

export const Description = ({ content }) => (
  <p className="step-description">{content}</p>
);

Description.propTypes = {
  // props
  content: PropTypes.string.isRequired,
};

export default Description;
