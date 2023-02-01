import React from 'react';
import PropTypes from 'prop-types';

// Components
import ArticleViewerLegend from '@components/common/article_viewer_legend.jsx';

const printArticleViewer = () => {
  const printWindow = window.open('', '_blank', '');
  const doc = printWindow.document;

  doc.open();
  doc.write(document.querySelector('#article-scrollbox-id').innerHTML);

  // copy over the stylesheets
  document.head.querySelectorAll('link, style').forEach((htmlElement) => {
    doc.head.appendChild(htmlElement.cloneNode(true));
  });
  doc.close();
  printWindow.focus();

  // Loading the stylesheets can take a while, so we wait a bit before printing.
  setTimeout(() => {
    printWindow.print();
  }, 500);
};

export const Footer = ({
  article, colors, failureMessage, showArticleFinder, highlightedHtml, isWhocolorLang,
  whocolorFailed, users
}) => {
  // Determine the Article Viewer Legend status based on what information
  // has returned from various API calls.
  let articleViewerLegend;
  if (!showArticleFinder) {
    let legendStatus;
    if (highlightedHtml) {
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
      />
    );
  }

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
        }}
        onClick={printArticleViewer}
      >
        Print
      </button>
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
