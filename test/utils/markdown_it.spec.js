import '../testHelper';
import markdownIt from '../../app/assets/javascripts/utils/markdown_it';

describe('markdown', () => {
  describe('links', () => {
    test('linkifies by default', () => {
      const md = markdownIt();
      const output = md.render('http://google.com');
      const expected = '<p><a href="http://google.com">http://google.com</a></p>\n';
      expect(output).toBe(expected);
    });

    test('opens links in new windows with openLinksExternally option', () => {
      const md = markdownIt({ openLinksExternally: true });
      const output = md.render('http://google.com');
      const expected = '<p><a href="http://google.com" target="_blank">http://google.com</a></p>\n';
      expect(output).toBe(expected);
    });
  });

  describe('html', () => {
    test('allows embedded html by default', () => {
      const md = markdownIt();
      const output = md.render('# h1\n\n<h2>test</h2>\n');
      const expected = '<h1>h1</h1>\n<h2>test</h2>\n';
      expect(output).toBe(expected);
    });
  });

  // Training modules, slides and quizzes on the Programs & Events Dashboard
  // are imported from Meta wiki pages that anyone may edit, and the rendered
  // output is handed to dangerouslySetInnerHTML, so `html: true` has to be
  // paired with sanitizing.
  describe('sanitizing', () => {
    test('removes script elements', () => {
      const output = markdownIt().render('Intro <script>alert(1)</script> outro');
      expect(output).not.toContain('<script');
    });

    test('removes event handler attributes', () => {
      const output = markdownIt().render('<img src="x" onerror="alert(1)">');
      expect(output).not.toContain('onerror');
    });

    test('removes javascript: urls', () => {
      const output = markdownIt().render('<a href="javascript:alert(1)">click</a>');
      expect(output).not.toContain('javascript:');
    });

    test('removes iframes', () => {
      const output = markdownIt().render('<iframe src="https://evil.example"></iframe>');
      expect(output).not.toContain('<iframe');
    });

    test('keeps the formatting training content relies on', () => {
      const output = markdownIt().render(
        '**bold** and *italic*\n\n- one\n- two\n\n<div class="wrapper"><p>block</p></div>'
      );
      expect(output).toContain('<strong>bold</strong>');
      expect(output).toContain('<em>italic</em>');
      expect(output).toContain('<li>one</li>');
      expect(output).toContain('<div class="wrapper">');
    });

    test('keeps images and links', () => {
      const output = markdownIt().render('![alt](https://example.org/a.png)\n\n[text](https://example.org)');
      expect(output).toContain('src="https://example.org/a.png"');
      expect(output).toContain('href="https://example.org"');
    });

    test('keeps footnote markup', () => {
      const output = markdownIt().render('Statement[^1]\n\n[^1]: The note.');
      expect(output).toContain('footnote');
    });
  });
});
