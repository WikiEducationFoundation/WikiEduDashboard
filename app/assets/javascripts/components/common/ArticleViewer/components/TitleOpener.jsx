import React from 'react';
import PropTypes from 'prop-types';

export const TitleOpener = ({ showArticle, showButtonClass, showButtonLabel, title }) => (
  <div className={`tooltip-trigger ${showButtonClass || ''}`}>
    <button style={{ textAlign: 'left' }} onClick={showArticle} aria-describedby="icon-article-viewer-desc">{title}</button>
    <p id="icon-article-viewer-desc">Open Article Viewer</p>
    <div className="tooltip tooltip-title dark large">
      <p>{showButtonLabel()}</p>
    </div>
  </div>
);

TitleOpener.propTypes = {
  showArticle: PropTypes.func.isRequired,
  showButtonClass: PropTypes.bool,
  showButtonLabel: PropTypes.func.isRequired,
  title: PropTypes.string.isRequired
};

export default TitleOpener;
