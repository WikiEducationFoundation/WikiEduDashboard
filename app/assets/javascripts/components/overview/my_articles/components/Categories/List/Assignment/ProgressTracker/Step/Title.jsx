import React from 'react';
import PropTypes from 'prop-types';

export const Title = ({ title }) => (
  <h3 className="step-title">{title}</h3>
);

Title.propTypes = {
  // props
  title: PropTypes.string.isRequired,
};

export default Title;
