import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../utils/article_utils';

export const TitleOpener = ({ showArticle, showButtonClass, showButtonLabel, title, buttonRef }) => (
  <div className={`tooltip-trigger ${showButtonClass || ''}`}>
    <button
      style={{ textAlign: 'left' }}
      onClick={showArticle}
      aria-describedby="icon-article-viewer-desc"
      ref={buttonRef}
    >
      {title}
    </button>
    <p id="icon-article-viewer-desc">{ArticleUtils.I18n('article_viewer', 'general')}</p>
    <div className="tooltip tooltip-title dark large">
      <p>{showButtonLabel()}</p>
    </div>
  </div>
);

TitleOpener.propTypes = {
  showArticle: PropTypes.func.isRequired,
  showButtonClass: PropTypes.bool,
  buttonRef: PropTypes.shape({
    current: PropTypes.any
  }),
  showButtonLabel: PropTypes.func.isRequired,
  title: PropTypes.string.isRequired
};

export default TitleOpener;
