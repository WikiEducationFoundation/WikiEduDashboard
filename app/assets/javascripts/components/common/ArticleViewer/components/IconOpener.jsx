/* eslint-disable react/jsx-indent */
import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../utils/article_utils';

export const IconOpener = ({ showArticle, showButtonClass, showButtonLabel, article }) => (
  article.id ? (
    <div className={`tooltip-trigger ${showButtonClass}`}>
      <button
        onClick={showArticle}
        aria-label="Open Article Viewer"
        className="icon icon-article-viewer"
      />
      <div className="tooltip tooltip-center dark large">
        <p>{showButtonLabel()}</p>
      </div>
    </div>
  ) : (
      <div className={`tooltip-trigger ${showButtonClass}`}>
        <button
          aria-label="Open Article Viewer"
          className="icon icon-article-viewer-disabled"
          disabled
        />
        <div className="tooltip tooltip-center dark large">
          <p>{ArticleUtils.I18n('article_not_found', article.project)}</p>
        </div>
      </div>
  )
);

IconOpener.propTypes = {
  showArticle: PropTypes.func.isRequired,
  showButtonClass: PropTypes.string,
  showButtonLabel: PropTypes.func.isRequired,
  article: PropTypes.shape({
    id: PropTypes.number,
    language: PropTypes.string,
    project: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  }),
};

export default IconOpener;
