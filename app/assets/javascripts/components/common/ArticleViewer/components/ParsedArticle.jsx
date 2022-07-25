import React from 'react';
import PropTypes from 'prop-types';


const wikilinkMatcher = new RegExp('<a href=', 'g');
const blankTargetLink = '<a target="_blank" href=';

export const ParsedArticle = ({ highlightedHtml, whocolorHtml, parsedArticle }) => {
  let articleHTML = highlightedHtml || whocolorHtml || parsedArticle;

  // This sets `target="_blank"` for all of the link in the article HTML,
  // so that clicking one will open it in a new tab.
  articleHTML = articleHTML?.replace(wikilinkMatcher, blankTargetLink);

  return (
    <div className="parsed-article" dangerouslySetInnerHTML={{ __html: articleHTML }} />
  );
};

ParsedArticle.propTypes = {
  highlightedHtml: PropTypes.string,
  whocolorHtml: PropTypes.string,
  parsedArticle: PropTypes.string
};

export default ParsedArticle;
