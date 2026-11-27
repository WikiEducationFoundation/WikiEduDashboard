import React, { useMemo } from 'react';
import PropTypes from 'prop-types';

const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

const processAuthorshipHtml = (html) => {
  if (!html || typeof window === 'undefined' || !window.DOMParser) return html;
  if (!html.includes('user-highlight-')) return html;

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
      const addedByText = I18n.t('articles.added_by', { author: editorName });

      const parent = group[0].parentNode;
      const firstSpan = group[0];
      const lastSpan = group[group.length - 1];

      // Collect all child nodes between firstSpan and lastSpan (inclusive)
      const nodesToWrap = [];
      let current = firstSpan;
      while (current) {
        nodesToWrap.push(current);
        if (current === lastSpan) break;
        current = current.nextSibling;
      }

      // A visually hidden label opens the run for screen readers. It's plain
      // text rather than an aria-label, since a labelled wrapper needs a role
      // and screen readers announce the role ("group") along with the label.
      // The editor's name becomes a hover tooltip only while the pointer is
      // over the run (see showRunTooltip), so screen readers don't read it too.
      const wrapper = doc.createElement('span');
      wrapper.className = 'authorship-run';
      wrapper.setAttribute('data-editor', editorName);
      const label = doc.createElement('span');
      label.className = 'authorship-run__label';
      // The leading space keeps the label from running into the previous word.
      label.textContent = ` ${addedByText}`;
      wrapper.appendChild(label);

      parent.insertBefore(wrapper, firstSpan);
      nodesToWrap.forEach((node) => {
        if (node.nodeType === 1) {
          node.removeAttribute('title');
        }
        wrapper.appendChild(node);
      });
    });

    return doc.body.innerHTML;
  } catch (error) {
    console.error('Failed to parse or process authorship HTML:', error);
    return html;
  }
};

// Authorship runs carry the editor's name in data-editor rather than a title,
// because screen readers read a title aloud after the run's label. Adding the
// title only while the pointer is over the run keeps the native tooltip.
const showRunTooltip = (event) => {
  const run = event.target.closest?.('.authorship-run');
  if (run && !run.hasAttribute('title')) run.setAttribute('title', run.dataset.editor);
};

const hideRunTooltip = (event) => {
  const run = event.target.closest?.('.authorship-run');
  if (run && !run.contains(event.relatedTarget)) run.removeAttribute('title');
};

export const ParsedArticle = ({ html, onInnerHTMLClick, onInnerHTMLKeyDown }) => {
  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  const articleHTML = html?.replace(httpLinkMatcher, blankTargetLink);
  const processedHTML = useMemo(() => processAuthorshipHtml(articleHTML), [articleHTML]);

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
      // The tooltip handlers have no keyboard counterpart because the runs
      // aren't focusable; screen readers get the name from the run's label.
      // eslint-disable-next-line jsx-a11y/mouse-events-have-key-events
      onMouseOver={showRunTooltip}
      // eslint-disable-next-line jsx-a11y/mouse-events-have-key-events
      onMouseOut={hideRunTooltip}
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
