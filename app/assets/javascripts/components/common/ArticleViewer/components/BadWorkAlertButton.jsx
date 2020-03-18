import React from 'react';
import PropTypes from 'prop-types';

export const BadWorkAlertButton = ({ showBadArticleAlert }) => (
  <a
    className="button danger small pull-right article-viewer-button"
    onClick={showBadArticleAlert}
  >
    Report Unsatisfactory Work
  </a>
);

BadWorkAlertButton.propTypes = {
  showBadArticleAlert: PropTypes.func.isRequired
};

export default BadWorkAlertButton;
