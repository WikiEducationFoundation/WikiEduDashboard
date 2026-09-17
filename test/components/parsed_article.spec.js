import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const ParsedArticle = require('../../app/assets/javascripts/components/common/ArticleViewer/components/ParsedArticle').default;

describe('ParsedArticle Screen Reader Boundaries', () => {
  test('groups contiguous editor highlight spans and injects screen reader announcement spans', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    // Contiguous spans by UserA, followed by a span by UserB, and a non-highlighted span
    const mockHtml = `
      <p>
        hello
        <span class="editor-token token-editor-123 user-highlight-1" title="UserA">world</span>
        <span class="editor-token token-editor-123 user-highlight-1" title="UserA">wide</span>
        web
        <span class="editor-token token-editor-456 user-highlight-2" title="UserB">page</span>
        <span class="some-other-span">untouched</span>
      </p>
    `;

    act(() => {
      createRoot(container).render(
        React.createElement(ParsedArticle, { html: mockHtml })
      );
    });

    const parsedArticleDiv = container.querySelector('.parsed-article');
    expect(parsedArticleDiv).not.toBeNull();

    // Check screen reader start/end boundary elements for UserA
    const srSpans = parsedArticleDiv.querySelectorAll('span.screen-reader');
    expect(srSpans.length).toBe(4);

    expect(srSpans[0].textContent).toBe('Edited by UserA');
    expect(srSpans[1].textContent).toBe('End edit');
    expect(srSpans[2].textContent).toBe('Edited by UserB');
    expect(srSpans[3].textContent).toBe('End edit');

    // Check that individual target token spans have aria-hidden and role="presentation"
    const userASpans = parsedArticleDiv.querySelectorAll('span.user-highlight-1');
    expect(userASpans.length).toBe(2);
    userASpans.forEach((span) => {
      expect(span.getAttribute('aria-hidden')).toBe('true');
      expect(span.getAttribute('role')).toBe('presentation');
    });

    const userBSpan = parsedArticleDiv.querySelector('span.user-highlight-2');
    expect(userBSpan.getAttribute('aria-hidden')).toBe('true');
    expect(userBSpan.getAttribute('role')).toBe('presentation');

    // Verify non-highlighted element remains untouched (no aria-hidden or role)
    const untouchedSpan = parsedArticleDiv.querySelector('.some-other-span');
    expect(untouchedSpan.getAttribute('aria-hidden')).toBeNull();
    expect(untouchedSpan.getAttribute('role')).toBeNull();
    expect(untouchedSpan.textContent).toBe('untouched');

    document.body.removeChild(container);
  });
});
