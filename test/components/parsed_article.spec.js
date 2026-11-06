import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const ParsedArticle = require('../../app/assets/javascripts/components/common/ArticleViewer/components/ParsedArticle').default;

describe('ParsedArticle Authorship Groups', () => {
  test('groups contiguous editor highlight spans and moves author metadata to the wrapper', () => {
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

    // Check wrapper elements with role="group" and aria-label for UserA and UserB
    const groupWrappers = parsedArticleDiv.querySelectorAll('span[role="group"]');
    expect(groupWrappers.length).toBe(2);

    expect(groupWrappers[0].getAttribute('aria-label')).toBe('Edited by UserA');
    expect(groupWrappers[1].getAttribute('aria-label')).toBe('Edited by UserB');

    // Confirm no stray screen-reader spans are injected
    const srSpans = parsedArticleDiv.querySelectorAll('span.screen-reader');
    expect(srSpans.length).toBe(0);

    // Verify copy/paste textContent does not contain screen reader announcements
    const rawText = parsedArticleDiv.textContent.replace(/\s+/g, ' ').trim();
    expect(rawText).toBe('hello world wide web page untouched');
    expect(rawText).not.toContain('Edited by');

    // Check that individual tokens remain exposed and inherit the wrapper tooltip.
    const userASpans = groupWrappers[0].querySelectorAll('span.user-highlight-1');
    expect(userASpans.length).toBe(2);
    userASpans.forEach((span) => {
      expect(span.getAttribute('aria-hidden')).toBeNull();
      expect(span.hasAttribute('title')).toBe(false);
    });

    const userBSpan = groupWrappers[1].querySelector('span.user-highlight-2');
    expect(userBSpan.getAttribute('aria-hidden')).toBeNull();
    expect(userBSpan.hasAttribute('title')).toBe(false);
    expect(groupWrappers[0].getAttribute('title')).toBe('UserA');
    expect(groupWrappers[1].getAttribute('title')).toBe('UserB');

    document.body.removeChild(container);
  });
});
