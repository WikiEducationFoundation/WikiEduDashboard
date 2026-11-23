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
  test('groups contiguous editor highlight spans and labels each run for screen readers', () => {
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

    // Each run of one editor's tokens gets a wrapper opened by a label for screen readers
    const runs = parsedArticleDiv.querySelectorAll('span.authorship-run');
    expect(runs.length).toBe(2);

    const labels = Array.from(runs).map(run => run.firstElementChild);
    labels.forEach(label => expect(label.className).toBe('authorship-run__label'));
    expect(labels[0].textContent.trim()).toBe('Added by UserA');
    expect(labels[1].textContent.trim()).toBe('Added by UserB');

    // No role, so screen readers have no "group" to announce
    expect(parsedArticleDiv.querySelector('[role]')).toBeNull();

    // Apart from the labels, the article text is unchanged
    labels.forEach(label => label.remove());
    const rawText = parsedArticleDiv.textContent.replace(/\s+/g, ' ').trim();
    expect(rawText).toBe('hello world wide web page untouched');

    // Tokens stay exposed, and the editor's name moves to the run
    const userASpans = runs[0].querySelectorAll('span.user-highlight-1');
    expect(userASpans.length).toBe(2);
    userASpans.forEach((span) => {
      expect(span.getAttribute('aria-hidden')).toBeNull();
      expect(span.hasAttribute('title')).toBe(false);
    });

    const userBSpan = runs[1].querySelector('span.user-highlight-2');
    expect(userBSpan.getAttribute('aria-hidden')).toBeNull();
    expect(userBSpan.hasAttribute('title')).toBe(false);
    expect(runs[0].dataset.editor).toBe('UserA');
    expect(runs[1].dataset.editor).toBe('UserB');

    document.body.removeChild(container);
  });

  test('shows the editor name as a tooltip only while the pointer is over a run', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);
    const mockHtml = `
      <p>
        <span class="editor-token token-editor-123 user-highlight-1" title="UserA">world</span>
        <span class="editor-token token-editor-123 user-highlight-1" title="UserA">wide</span>
        web
      </p>
    `;

    act(() => {
      createRoot(container).render(
        React.createElement(ParsedArticle, { html: mockHtml })
      );
    });

    const run = container.querySelector('span.authorship-run');
    const [firstToken, secondToken] = run.querySelectorAll('span.user-highlight-1');
    const outside = container.querySelector('p');
    const hover = (target, related) => {
      act(() => {
        target.dispatchEvent(new MouseEvent('mouseover', { bubbles: true, relatedTarget: related }));
      });
    };
    const leave = (target, related) => {
      act(() => {
        target.dispatchEvent(new MouseEvent('mouseout', { bubbles: true, relatedTarget: related }));
      });
    };

    expect(run.hasAttribute('title')).toBe(false);

    hover(firstToken, outside);
    expect(run.getAttribute('title')).toBe('UserA');

    // Moving between tokens of the same run keeps the tooltip
    leave(firstToken, secondToken);
    hover(secondToken, firstToken);
    expect(run.getAttribute('title')).toBe('UserA');

    leave(secondToken, outside);
    expect(run.hasAttribute('title')).toBe(false);

    document.body.removeChild(container);
  });
});
