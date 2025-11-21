import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';


const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

export const ParsedArticle = ({ highlightedHtml, whocolorHtml, parsedArticle }) => {
  const containerRef = useRef(null);
  let articleHTML = highlightedHtml || whocolorHtml || parsedArticle;

  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  articleHTML = articleHTML?.replace(httpLinkMatcher, blankTargetLink);

  useEffect(() => {
    if (!highlightedHtml) return undefined;

    const id = setTimeout(() => {
      if (!containerRef.current) return;
      const spans = containerRef.current.querySelectorAll('.editor-token');
      if (!spans.length) return;

      const spanArray = Array.from(spans);
      let lastUserId = null;
      let lastClass = null;

      spanArray.forEach((span, index) => {
        const m = span.className.match(/token-editor-(\d+)/);
        if (!m) return;
        const uid = m[1];
        const cls = span.className.split(' ').find(s => s.startsWith('user-highlight-'));

        // Check if this is the start of a new group
        const isNewGroup = uid !== lastUserId || cls !== lastClass;
        
        // Check if this is the last span in the current group
        const nextSpan = spanArray[index + 1];
        const isLastInGroup = !nextSpan || (() => {
          const nextMatch = nextSpan.className.match(/token-editor-(\d+)/);
          if (!nextMatch) return true;
          const nextUid = nextMatch[1];
          const nextCls = nextSpan.className.split(' ').find(s => s.startsWith('user-highlight-'));
          return nextUid !== uid || nextCls !== cls;
        })();

        // Mark the first span of a new group
        if (isNewGroup) {
          const name = span.getAttribute('title');
          if (name) {
            span.setAttribute('aria-label', `Edited by ${name.replace(/"/g, '&quot;')}`);
          }
        }

        // Mark the last span of the current group
        if (isLastInGroup) {
          const name = span.getAttribute('title');
          if (name) {
            const currentLabel = span.getAttribute('aria-label') || '';
            // If it already has "Edited by", append "End edit", otherwise add "End edit by [user]"
            const endEditText = currentLabel.includes('Edited by') ? ' End edit' : `End edit by ${name.replace(/"/g, '&quot;')}`;
            span.setAttribute('aria-label', `${currentLabel}${endEditText}`.trim());
          }
        }

        lastUserId = uid;
        lastClass = cls;
      });
    }, 10);

    return () => clearTimeout(id);
  }, [highlightedHtml]);

  return (
    <div ref={containerRef} className="parsed-article" dangerouslySetInnerHTML={{ __html: articleHTML }} />
  );
};

ParsedArticle.propTypes = {
  highlightedHtml: PropTypes.string,
  whocolorHtml: PropTypes.string,
  parsedArticle: PropTypes.string
};

export default ParsedArticle;
