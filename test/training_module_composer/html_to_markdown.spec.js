import '../testHelper';
import { htmlToMarkdown } from '../../app/assets/javascripts/training_module_composer/utils/html_to_markdown.js';

describe('htmlToMarkdown', () => {
  test('converts basic headings, bold, and paragraphs', () => {
    const html = '<h2>Intro</h2><p>Hello <strong>world</strong>.</p>';
    expect(htmlToMarkdown(html)).toBe('## Intro\n\nHello **world**.');
  });

  test('converts h1 headings', () => {
    expect(htmlToMarkdown('<h1>Title</h1><p>Body.</p>')).toBe('# Title\n\nBody.');
  });

  test('strips the Google Docs outer <b> wrapper', () => {
    const html = [
      '<b id="docs-internal-guid-abc123" style="font-weight: normal">',
      '<h2>Real heading</h2><p>Body text.</p>',
      '</b>'
    ].join('');
    expect(htmlToMarkdown(html)).toBe('## Real heading\n\nBody text.');
  });

  test('strips nested Google Docs <b> wrappers', () => {
    const html = [
      '<b id="docs-internal-guid-outer" style="font-weight: normal">',
      '<b id="docs-internal-guid-inner">',
      '<h2>Heading</h2><p>Body.</p>',
      '</b></b>'
    ].join('');
    expect(htmlToMarkdown(html)).toBe('## Heading\n\nBody.');
  });

  test('converts bulleted lists', () => {
    const html = '<ul><li>one</li><li>two</li></ul>';
    const result = htmlToMarkdown(html);
    expect(result).toMatch(/^-\s+one$/m);
    expect(result).toMatch(/^-\s+two$/m);
  });

  test('preserves links', () => {
    const html = '<p>See <a href="https://example.org">Example</a>.</p>';
    expect(htmlToMarkdown(html)).toBe('See [Example](https://example.org).');
  });

  test('drops style and class attributes', () => {
    const html = '<h2 style="color:red" class="foo">Heading</h2><p>Body.</p>';
    expect(htmlToMarkdown(html)).toBe('## Heading\n\nBody.');
  });

  test('returns empty string on empty input', () => {
    expect(htmlToMarkdown('')).toBe('');
  });
});
