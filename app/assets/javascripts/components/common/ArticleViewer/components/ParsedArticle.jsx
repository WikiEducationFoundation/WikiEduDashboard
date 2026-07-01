import React from 'react';
import PropTypes from 'prop-types';


const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

export const ParsedArticle = ({ html, onInnerHTMLClick, onInnerHTMLKeyDown }) => {
  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  const articleHTML = html?.replace(httpLinkMatcher, blankTargetLink);

  // `onInnerHTMLClick`/`onInnerHTMLKeyDown` let a highlight feature respond to
  // clicks and keyboard activation on the injected HTML (e.g. claim verification
  // tagging citation markers as focusable buttons). React's synthetic events
  // bubble from dangerouslySetInnerHTML content to these handlers, so the feature
  // can delegate via event.target.closest(...). Native <a> links activate with
  // Enter (firing a click) on their own; the keydown handler covers the
  // role="button" claim spans, which need Enter/Space handled explicitly. Both
  // are omitted by features that don't need them (authorship, the default no-op).
  return (
    // eslint-disable-next-line jsx-a11y/no-static-element-interactions
    <div
      className="parsed-article"
      onClick={onInnerHTMLClick}
      onKeyDown={onInnerHTMLKeyDown}
      dangerouslySetInnerHTML={{ __html: articleHTML }}
    />
  );
};

ParsedArticle.propTypes = {
  html: PropTypes.string,
  onInnerHTMLClick: PropTypes.func,
  onInnerHTMLKeyDown: PropTypes.func
};

export default ParsedArticle;
