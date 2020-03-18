import React from 'react';
import PropTypes from 'prop-types';

export const ParsedArticle = ({ highlightedHtml, whocolorHtml, parsedArticle }) => {
  const articleHTML = highlightedHtml || whocolorHtml || parsedArticle;
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
