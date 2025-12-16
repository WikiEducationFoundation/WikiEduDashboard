import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';


const httpLinkMatcher = /(<a href="http)/g;
const blankTargetLink = '<a target="_blank" href="http';

export const ParsedArticle = ({ highlightedHtml, whocolorHtml, parsedArticle, language }) => {
  const containerRef = useRef(null);
  let articleHTML = highlightedHtml || whocolorHtml || parsedArticle;

  // This sets `target="_blank"` for all of the non-anchor links in the article HTML,
  // so that clicking one will open it in a new tab.
  articleHTML = articleHTML?.replace(httpLinkMatcher, blankTargetLink);

  // Make paragraphs focusable (if they don't already have a tabindex)
  if (articleHTML) {
    articleHTML = articleHTML.replace(/<p(?![^>]*tabindex)/g, '<p tabindex="0"');
  }

  // Add visually hidden text announcements for screenreaders (replaces group-based aria-labels)
  useEffect(() => {
    if (!highlightedHtml) return undefined;

    const id = setTimeout(() => {
      if (!containerRef.current) return;
      const spans = containerRef.current.querySelectorAll('.editor-token');
      if (!spans.length) return;

      // Simple approach: only process highlighted spans with valid authors
      const spanArray = Array.from(spans);
      const validSpans = [];
      
      // First pass: collect only highlighted spans with valid authors, with their original indices
      spanArray.forEach((span, originalIndex) => {
        const className = span.className || '';
        // Must have user-highlight-* class
        if (!className.split(' ').some(cls => cls.startsWith('user-highlight-'))) {
          return;
        }
        // Must have valid title
        const name = span.getAttribute('title');
        if (!name || name.trim() === '' || name.trim().toLowerCase() === 'unknown') {
          return;
        }
        validSpans.push({ span, originalIndex });
      });

      // Second pass: add visually hidden text announcements to valid spans only
      let previousUserId = null;
      validSpans.forEach((item, index) => {
        const { span, originalIndex } = item;
        const className = span.className || '';
        const m = className.match(/token-editor-(\d+)/);
        if (!m) return;
        const uid = m[1];
        const name = span.getAttribute('title').trim();

        // Simple transition detection (no group logic)
        const isNewUser = uid !== previousUserId;
        
        // Check if this is the last span in the edit
        // It's the last if:
        // 1. There's no next valid span, OR
        // 2. The next valid span has a different user ID, OR
        // 3. The next span in the original array is not highlighted (transition to non-highlighted)
        const nextValidSpan = validSpans[index + 1];
        const nextValidMatch = nextValidSpan ? nextValidSpan.span.className.match(/token-editor-(\d+)/) : null;
        const nextValidUid = nextValidMatch ? nextValidMatch[1] : null;
        
        // Check the next span in the original array to see if it's highlighted
        const nextOriginalSpan = spanArray[originalIndex + 1];
        const nextOriginalIsHighlighted = nextOriginalSpan ? 
          (nextOriginalSpan.className || '').split(' ').some(cls => cls.startsWith('user-highlight-')) : false;
        
        const isLastInEdit = !nextValidSpan || 
                            (nextValidUid !== uid) || 
                            !nextOriginalIsHighlighted;

        // Announce at start of edit using visually hidden text (more reliable with VoiceOver)
        if (isNewUser) {
          span.removeAttribute('title');
          // Remove any existing aria-labels to avoid "group" announcements
          span.removeAttribute('aria-label');
          span.removeAttribute('aria-atomic');
          // Insert visually hidden text as a sibling before the span so it's read before the word content
          // This ensures screenreaders announce "Edited by [name]" before reading the actual word
          // We place it as a sibling (not child) because parent spans have aria-hidden="true"
          const hiddenText = document.createElement('span');
          hiddenText.className = 'screen-reader';
          hiddenText.textContent = `Edited by ${name}`;
          if (span.parentNode) {
            span.parentNode.insertBefore(hiddenText, span);
          }
        }

        // Announce at end of edit using visually hidden text
        if (isLastInEdit) {
          // Remove any existing aria-labels to avoid "group" announcements
          span.removeAttribute('aria-label');
          span.removeAttribute('aria-atomic');
          // Insert visually hidden text as a sibling after the span
          // We place it as a sibling (not child) because parent spans have aria-hidden="true"
          const hiddenText = document.createElement('span');
          hiddenText.className = 'screen-reader';
          hiddenText.textContent = 'End edit';
          if (span.parentNode) {
            span.parentNode.insertBefore(hiddenText, span.nextSibling);
          }
        }

        previousUserId = uid;
      });
      // Make editor-token spans invisible to assistive tech so screen readers
      // read the enclosing paragraph as a single unit instead of word-by-word.
      // Note: The visually hidden text children have aria-hidden="false" so they remain accessible
      spanArray.forEach((span) => {
        try {
          span.setAttribute('aria-hidden', 'true');
          span.setAttribute('role', 'presentation');
          span.setAttribute('tabindex', '-1');
        } catch (e) {
          // ignore if setting attributes fails
        }
      });
    }, 10);

    return () => clearTimeout(id);
  }, [highlightedHtml]);
  // Paragraph-level read-aloud and keyboard navigation (paragraph-granularity)
  // Also create focusable per-word spans so users can Tab through words. This is
  // intentionally minimal: no UI toggles and no speech API usage for reading;
  // VoiceOver will speak focused words automatically.
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return undefined;


    // Create focusable *chunks* for each paragraph (only once per paragraph).
    // A chunk is a short run of text that ends at punctuation (.,;:!?), at a
    // link, or at paragraph end — closer to natural reading units than single
    // words.
    const createWordSpans = (p) => {
      if (p.getAttribute('data-words-initialized') === 'true') return;

      // Accumulate text into `current` and flush into a chunk span when needed
      let current = '';
      const flush = (targetParent) => {
        if (current && current.trim()) {
          const span = document.createElement('span');
          span.className = 'article-chunk';
          span.setAttribute('tabindex', '0');
          // Ensure assistive tech treats this as plain text, not a group.
          span.setAttribute('role', 'text');
          span.textContent = current;
          targetParent.appendChild(span);
        } else if (current) {
          // If current contains only whitespace, preserve it
          targetParent.appendChild(document.createTextNode(current));
        }
        current = '';
      };

      const processText = (text, targetParent) => {
        // Split into tokens of whitespace or punctuation or words
        const tokens = text.split(/(\s+|[.,;:!?\u2013\u2014]+)/);
        tokens.forEach((tok) => {
          if (!tok) return;
          if (/^\s+$/.test(tok)) {
            current += tok;
          } else if (/^[.,;:!?\u2013\u2014]+$/.test(tok)) {
            // punctuation: append then flush (end of chunk)
            current += tok;
            flush(targetParent);
          } else {
            // regular word/token
            current += tok;
          }
        });
      };

      const walk = (node, targetParent) => {
        if (node.nodeType === Node.TEXT_NODE) {
          processText(node.nodeValue, targetParent);
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          const tag = node.tagName.toLowerCase();
          if (tag === 'a') {
            // Links are boundaries — flush current chunk first, then append link
            flush(targetParent);
            try {
              const clone = node.cloneNode(true);
              targetParent.appendChild(clone);
            } catch (e) {
              try { targetParent.appendChild(node); } catch (err) { /* ignore */ }
            }
          } else {
            // For other elements, recurse so links inside are handled as boundaries
            Array.from(node.childNodes).forEach((child) => walk(child, targetParent));
          }
        }
      };

      const frag = document.createDocumentFragment();
      Array.from(p.childNodes).forEach((node) => walk(node, frag));
      // flush remainder
      flush(frag);

      // Replace paragraph content
      while (p.firstChild) p.removeChild(p.firstChild);
      p.appendChild(frag);
      // After converting to per-chunk focusable spans, remove paragraph tabindex
      // so Tab goes to chunks instead of the <p> element itself.
      try { p.removeAttribute('tabindex'); } catch (e) { /* ignore */ }
      p.setAttribute('data-words-initialized', 'true');
    };

    const paragraphs = Array.from(container.querySelectorAll('p'));
    paragraphs.forEach((p) => createWordSpans(p));

    // Keyboard handling for chunk focus: ArrowUp/ArrowDown to move between paragraphs
    const handleKeyDown = (event) => {
      const target = event.target;
      if (!target || !target.classList) return;
      // Only handle navigation for chunk elements
      if (!target.classList.contains('article-chunk')) return;

      if (event.key === 'ArrowDown') {
        // Move focus to first chunk of next paragraph
        const p = target.closest('p');
        if (p) {
          const paragraphs = Array.from(container.querySelectorAll('p'));
          const idx = paragraphs.indexOf(p);
          if (idx >= 0 && idx < paragraphs.length - 1) {
            const next = paragraphs[idx + 1];
            const nextChunk = next.querySelector('.article-chunk');
            if (nextChunk) {
              event.preventDefault();
              nextChunk.focus();
            } else {
              event.preventDefault();
              next.focus();
            }
          }
        }
      } else if (event.key === 'ArrowUp') {
        // Move focus to last chunk of previous paragraph
        const p = target.closest('p');
        if (p) {
          const paragraphs = Array.from(container.querySelectorAll('p'));
          const idx = paragraphs.indexOf(p);
          if (idx > 0) {
            const prev = paragraphs[idx - 1];
            const prevChunk = prev.querySelectorAll('.article-chunk');
            if (prevChunk && prevChunk.length) {
              event.preventDefault();
              prevChunk[prevChunk.length - 1].focus();
            } else {
              event.preventDefault();
              prev.focus();
            }
          }
        }
      }
    };

    container.addEventListener('keydown', handleKeyDown);

    // When a word gets focus, temporarily hide nearby labeled elements (like
    // editor-token spans) so VoiceOver doesn't announce group labels or names
    // along with the word. Restore them on blur.
    const handleFocusIn = (event) => {
      const tgt = event.target;
      if (!tgt || !tgt.classList || !tgt.classList.contains('article-chunk')) return;
      const p = tgt.closest('p');
      if (!p) return;

      // Hide labeled elements and 'role="group"' containers so VoiceOver
      // doesn't announce group labels or usernames while the chunk is focused.
      // We search the whole article container (not just the paragraph) to
      // avoid nearby labels from being spoken.
      const labeled = Array.from(container.querySelectorAll('[aria-label], .editor-token, [role="group"]'));
      labeled.forEach((el) => {
        if (el === tgt || el.contains(tgt)) return;
        if (el.getAttribute('data-prev-aria-hidden') === null) {
          const prev = el.getAttribute('aria-hidden');
          if (prev !== null) el.setAttribute('data-prev-aria-hidden', prev);
          else el.setAttribute('data-prev-aria-hidden', 'none');
        }
        try { el.setAttribute('aria-hidden', 'true'); } catch (e) { /* ignore */ }
      });
    };

    const handleFocusOut = (event) => {
      const tgt = event.target;
      if (!tgt || !tgt.classList || !tgt.classList.contains('article-chunk')) return;
      const p = tgt.closest('p');
      if (!p) return;

      const labeled = Array.from(container.querySelectorAll('[data-prev-aria-hidden], .editor-token'));
      labeled.forEach((el) => {
        const prev = el.getAttribute('data-prev-aria-hidden');
        if (prev === 'none') {
          el.removeAttribute('aria-hidden');
        } else if (prev !== null) {
          try { el.setAttribute('aria-hidden', prev); } catch (e) { /* ignore */ }
        }
        el.removeAttribute('data-prev-aria-hidden');
      });
    };

    container.addEventListener('focusin', handleFocusIn);
    container.addEventListener('focusout', handleFocusOut);

    return () => {
      container.removeEventListener('keydown', handleKeyDown);
      container.removeEventListener('focusin', handleFocusIn);
      container.removeEventListener('focusout', handleFocusOut);
    };
  }, [articleHTML]);

  return (
    <div ref={containerRef} className="parsed-article" role="article" dangerouslySetInnerHTML={{ __html: articleHTML }} />
  );
};

ParsedArticle.propTypes = {
  highlightedHtml: PropTypes.string,
  whocolorHtml: PropTypes.string,
  parsedArticle: PropTypes.string
  ,language: PropTypes.string
};

export default ParsedArticle;
