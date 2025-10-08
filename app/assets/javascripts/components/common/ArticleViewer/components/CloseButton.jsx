import React from 'react';
import PropTypes from 'prop-types';

export const CloseButton = ({ hideArticle }) => (
  <button
    type="button"
    aria-label="Close Article Viewer"
    className="pull-right article-viewer-button icon-close"
    onClick={hideArticle}
  />
);

CloseButton.propTypes = {
  hideArticle: PropTypes.func.isRequired
};

export default CloseButton;
