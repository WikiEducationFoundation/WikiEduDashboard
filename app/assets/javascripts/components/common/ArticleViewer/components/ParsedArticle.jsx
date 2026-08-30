import React from 'react';
import PropTypes from 'prop-types';


const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

const processAuthorshipHtml = (html) => {
  if (!html || typeof window === 'undefined' || !window.DOMParser) return html;

  try {
    const parser = new window.DOMParser();
    const doc = parser.parseFromString(html, 'text/html');

    const spans = Array.from(doc.querySelectorAll('span.editor-token'));
    const isTargetSpan = (span) => {
      const classList = span.className || '';
      const hasHighlightClass = /user-highlight-\d+/.test(classList);
      const hasTitle = span.hasAttribute('title') && span.getAttribute('title').trim() !== '';
      return hasHighlightClass && hasTitle;
    };

    const targetSpans = spans.filter(isTargetSpan);
    if (targetSpans.length === 0) return html;

    const areContiguous = (spanA, spanB) => {
      if (spanA.parentNode !== spanB.parentNode) return false;
      if (spanA.getAttribute('title') !== spanB.getAttribute('title')) return false;

      let next = spanA.nextSibling;
      while (next && next !== spanB) {
        if (next.nodeType === 3) { // Node.TEXT_NODE
          if (next.nodeValue.trim() !== '') return false;
        } else {
          return false;
        }
        next = next.nextSibling;
      }
      return next === spanB;
    };

    const groups = [];
    let currentGroup = [];

    targetSpans.forEach((span) => {
      if (currentGroup.length === 0) {
        currentGroup.push(span);
      } else {
        const lastSpan = currentGroup[currentGroup.length - 1];
        if (areContiguous(lastSpan, span)) {
          currentGroup.push(span);
        } else {
          groups.push(currentGroup);
          currentGroup = [span];
        }
      }
    });
    if (currentGroup.length > 0) {
      groups.push(currentGroup);
    }

    groups.forEach((group) => {
      const editorName = group[0].getAttribute('title');

      const firstSpan = group[0];
      const startSpan = doc.createElement('span');
      startSpan.className = 'screen-reader';
      startSpan.textContent = `Edited by ${editorName}`;
      firstSpan.parentNode.insertBefore(startSpan, firstSpan);

      const lastSpan = group[group.length - 1];
      const endSpan = doc.createElement('span');
      endSpan.className = 'screen-reader';
      endSpan.textContent = 'End edit';
      lastSpan.parentNode.insertBefore(endSpan, lastSpan.nextSibling);

      group.forEach((span) => {
        span.setAttribute('aria-hidden', 'true');
        span.setAttribute('role', 'presentation');
      });
    });

    return doc.body.innerHTML;
  } catch (error) {
    console.error('Failed to parse or process authorship HTML:', error);
    return html;
  }
};

export const ParsedArticle = ({ html, onInnerHTMLClick, onInnerHTMLKeyDown }) => {
  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  const articleHTML = html?.replace(httpLinkMatcher, blankTargetLink);
  const processedHTML = processAuthorshipHtml(articleHTML);

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
      dangerouslySetInnerHTML={{ __html: processedHTML }}
    />
  );
};

ParsedArticle.propTypes = {
  html: PropTypes.string,
  onInnerHTMLClick: PropTypes.func,
  onInnerHTMLKeyDown: PropTypes.func
};

export default ParsedArticle;
