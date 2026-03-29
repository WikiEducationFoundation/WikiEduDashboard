import React from 'react';
import PropTypes from 'prop-types';

// this progress bar sticks to its parent element
// see app/assets/stylesheets/modules/_loading.styl
const ProgressIndicator = ({ message }) => {
  return (
    <div className="progress-indicator" role="progressbar" aria-busy="true" aria-label={message}>
      <div className="text-center">
        <div className="loading__spinner__small" aria-hidden="true" />
        {message}
      </div>
    </div>
  );
};

ProgressIndicator.propTypes = {
  message: PropTypes.string
};

export default ProgressIndicator;
