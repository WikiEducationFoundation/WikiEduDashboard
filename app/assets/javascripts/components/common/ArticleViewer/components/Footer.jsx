import React from 'react';
import PropTypes from 'prop-types';

// Components
import ArticleViewerLegend from '@components/common/article_viewer_legend.jsx';
import { printArticleViewer } from '../../../../utils/article_viewer';

export const Footer = ({
  article, colors, failureMessage, showArticleFinder, highlightedHtml, isWhocolorLang,
  whocolorFailed, users, unhighlightedContributors, revisionId, toggleRevisionHandler, pendingRequest
}) => {
  // Determine the Article Viewer Legend status based on what information
  // has returned from various API calls.
  let articleViewerLegend;
  if (!showArticleFinder) {
    let legendStatus;
    if (highlightedHtml && unhighlightedContributors.length) {
      legendStatus = 'ready';
    } else if (whocolorFailed) {
      legendStatus = 'failed';
    } else if (isWhocolorLang()) {
      legendStatus = 'loading';
    }

    articleViewerLegend = (
      <ArticleViewerLegend
        article={article}
        users={users}
        colors={colors}
        status={legendStatus}
        failureMessage={failureMessage}
        unhighlightedContributors={unhighlightedContributors}
      />
    );
  }

  const revision_button_text = revisionId ? I18n.t('application.show_current_revision') : I18n.t('application.show_last_revision');
  const revision_button = !showArticleFinder && (
    <div>
      {
        !showArticleFinder && (
          <button
            className="button dark small"
            style={{
              height: 'max-content',
              width: 'max-content',
            }}
            onClick={toggleRevisionHandler}
            disabled={pendingRequest}
          >
            {revision_button_text}
          </button>
        )
      }
    </div>
  );

  return (
    <div
      className="article-footer"
      style={{
      display: 'flex',
      alignItems: 'center',
      padding: '0 1em',
    }}
    >
      {articleViewerLegend}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '1em',
          width: '100%',
          justifyContent: 'flex-end',
        }}
      >
        {revision_button}
        <a
          className="button dark small pull-right article-viewer-button"
          href={article.url}
          target="_blank"
          style={{
            height: 'max-content',
            width: 'max-content',
            whiteSpace: 'nowrap'
          }}
        >
          {I18n.t('articles.view_on_wiki')}
        </a>
        <button
          className="button dark small"
          style={{
            height: 'max-content',
            width: 'max-content',
            margin: '0em 0em',
          }}
          onClick={printArticleViewer}
        >
          {I18n.t('application.print')}
        </button>
      </div>
    </div>
  );
};

Footer.propTypes = {
  article: PropTypes.object.isRequired,
  colors: PropTypes.array.isRequired,
  failureMessage: PropTypes.string,
  showArticleFinder: PropTypes.bool,
  highlightedHtml: PropTypes.string,
  isWhocolorLang: PropTypes.func.isRequired,
  whocolorFailed: PropTypes.bool,
  users: PropTypes.array
};

export default Footer;
