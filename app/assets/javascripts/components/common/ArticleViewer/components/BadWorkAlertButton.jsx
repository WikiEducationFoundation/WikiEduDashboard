import React from 'react';
import PropTypes from 'prop-types';

export const BadWorkAlertButton = ({ showBadArticleAlert }) => (
  <a
    className="button small pull-right article-viewer-button"
    onClick={showBadArticleAlert}
  >
    Quality Problems?
  </a>
);

BadWorkAlertButton.propTypes = {
  showBadArticleAlert: PropTypes.func.isRequired
};

export default BadWorkAlertButton;
