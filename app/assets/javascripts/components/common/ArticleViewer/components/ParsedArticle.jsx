import React from 'react';
import PropTypes from 'prop-types';


const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

export const ParsedArticle = ({ html }) => {
  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  const articleHTML = html?.replace(httpLinkMatcher, blankTargetLink);

  return (
    <div className="parsed-article" dangerouslySetInnerHTML={{ __html: articleHTML }} />
  );
};

ParsedArticle.propTypes = {
  html: PropTypes.string
};

export default ParsedArticle;
