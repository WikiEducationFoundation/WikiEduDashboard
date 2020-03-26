import React from 'react';
import PropTypes from 'prop-types';

export const IconOpener = ({ showArticle, showButtonClass, showButtonLabel }) => (
  <div className={`tooltip-trigger ${showButtonClass}`}>
    <button onClick={showArticle} aria-label="Open Article Viewer" className="icon icon-article-viewer" />
    <div className="tooltip tooltip-center dark large">
      <p>{showButtonLabel()}</p>
    </div>
  </div>
);

IconOpener.propTypes = {
  showArticle: PropTypes.func.isRequired,
  showButtonClass: PropTypes.string,
  showButtonLabel: PropTypes.func.isRequired
};

export default IconOpener;
