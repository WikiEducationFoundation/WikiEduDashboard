import React from 'react';
import PropTypes from 'prop-types';

const TrainingApp = ({ children }) => (
  <div>
    {children}
  </div>
);

TrainingApp.propTypes = {
  children: PropTypes.node
};

export default TrainingApp;
