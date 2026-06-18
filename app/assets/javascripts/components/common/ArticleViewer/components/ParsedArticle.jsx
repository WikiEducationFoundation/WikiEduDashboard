import React from 'react';
import PropTypes from 'prop-types';


const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

export const ParsedArticle = ({ html, onInnerHTMLClick }) => {
  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  const articleHTML = html?.replace(httpLinkMatcher, blankTargetLink);

  // `onInnerHTMLClick` lets a highlight feature respond to clicks on the injected
  // HTML (e.g. claim verification clicking a tagged citation marker). React's
  // synthetic events bubble from dangerouslySetInnerHTML content to this onClick,
  // so the feature can delegate via event.target.closest(...). Omitted by features
  // that don't need it (authorship, the default no-op), leaving plain rendering.
  // This div is a delegation root, not itself a control: the real interactive
  // targets in the injected HTML are native <a> elements, so keyboard activation
  // (Enter) already fires a click that bubbles here — hence the a11y disable.
  return (
    // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions
    <div
      className="parsed-article"
      onClick={onInnerHTMLClick}
      dangerouslySetInnerHTML={{ __html: articleHTML }}
    />
  );
};

ParsedArticle.propTypes = {
  html: PropTypes.string,
  onInnerHTMLClick: PropTypes.func
};

export default ParsedArticle;
