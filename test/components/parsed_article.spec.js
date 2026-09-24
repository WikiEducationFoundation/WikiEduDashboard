import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
if (typeof I18n !== 'undefined') {
  I18n.translations = I18n.translations || {};
  I18n.translations.en = I18n.translations.en || {};
  I18n.translations.en.articles = I18n.translations.en.articles || {};
  I18n.translations.en.articles.edited_by = 'Edited by %{author}';
  I18n.translations.en.articles.end_edit = 'End edit';
}

const ParsedArticle = require('../../app/assets/javascripts/components/common/ArticleViewer/components/ParsedArticle').default;

describe('ParsedArticle Screen Reader Boundaries', () => {



  const accessibleText = (root) => {
    const parts = [];
    const walk = (node) => {
      if (node.nodeType === 1 && node.getAttribute('aria-hidden') === 'true') return;
      if (node.nodeType === 3) {
        parts.push(node.nodeValue);
        return;
      }
      Array.from(node.childNodes).forEach(walk);
    };
    walk(root);
    return parts.join('').replace(/\s+/g, ' ').trim();
  };

  test('groups contiguous editor highlight spans, injects boundaries, and preserves article text in accessibility tree', () => {
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

    // Check screen reader start/end boundary elements for UserA and UserB
    const srSpans = parsedArticleDiv.querySelectorAll('span.screen-reader');
    expect(srSpans.length).toBe(4);

    expect(srSpans[0].textContent).toBe(' Edited by UserA ');
    expect(srSpans[1].textContent).toBe(' End edit ');
    expect(srSpans[2].textContent).toBe(' Edited by UserB ');
    expect(srSpans[3].textContent).toBe(' End edit ');

    // Check that individual target token spans DO NOT have aria-hidden (text is NOT hidden)
    const userASpans = parsedArticleDiv.querySelectorAll('span.user-highlight-1');
    expect(userASpans.length).toBe(2);
    userASpans.forEach((span) => {
      expect(span.getAttribute('aria-hidden')).toBeNull();
      expect(span.getAttribute('role')).toBeNull();
      expect(span.getAttribute('title')).toBeNull();
    });

    const userBSpan = parsedArticleDiv.querySelector('span.user-highlight-2');
    expect(userBSpan.getAttribute('aria-hidden')).toBeNull();
    expect(userBSpan.getAttribute('role')).toBeNull();
    expect(userBSpan.getAttribute('title')).toBeNull();

    // Verify accessible text contains BOTH the boundary announcements AND the full article text
    const spoken = accessibleText(parsedArticleDiv);
    expect(spoken).toContain('Edited by UserA');
    expect(spoken).toContain('world wide');
    expect(spoken).toContain('End edit');
    expect(spoken).toContain('Edited by UserB');
    expect(spoken).toContain('page');
    expect(spoken).toBe('hello Edited by UserA world wide End edit web Edited by UserB page End edit untouched');

    document.body.removeChild(container);
  });
});
