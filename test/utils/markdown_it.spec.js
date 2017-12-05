import '../testHelper';
import markdownIt from '../../app/assets/javascripts/utils/markdown_it';

describe('markdown', () => {
  describe('links', () => {
    it('linkifies by default', () => {
      const md = markdownIt();
      const output = md.render('http://google.com');
      const expected = '<p><a href="http://google.com">http://google.com</a></p>\n';
      expect(output).to.eq(expected);
    });

    it('opens links in new windows with openLinksExternally option', () => {
      const md = markdownIt({ openLinksExternally: true });
      const output = md.render('http://google.com');
      const expected = '<p><a href="http://google.com" target="_blank">http://google.com</a></p>\n';
      expect(output).to.eq(expected);
    });
  });

  describe('html', () => {
    it('allows embedded html by default', () => {
      const md = markdownIt();
      const output = md.render('# h1\n\n<h2>test</h2>\n');
      const expected = '<h1>h1</h1>\n<h2>test</h2>\n';
      expect(output).to.eq(expected);
    });
  });
});
