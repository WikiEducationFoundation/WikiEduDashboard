import { URLBuilder } from './URLBuilder';

describe('URLBuilder', () => {
  const defaults = {
    article: { language: 'en', project: 'wikipedia', title: 'Brown Bear, Brown Bear, What Do You See?' },
    users: ['user1', 'user2']
  };
  it('should be able to create a new instance of itself', () => {
    const helper = new URLBuilder({ article: defaults.article, users: defaults.users });
    expect(typeof helper).toEqual('object');
  });

  describe('#parsedArticleURL', () => {
    it('should create a parsedArticleURL when given a valid article', () => {
      const helper = new URLBuilder({ article: defaults.article });
      const expected = 'https://en.wikipedia.org/w/api.php?action=parse&disableeditsection=true&redirects=true&format=json&page=Brown%20Bear%2C%20Brown%20Bear%2C%20What%20Do%20You%20See%3F';
      expect(helper.parsedArticleURL()).toEqual(expected);
    });
    it('should throw an error if the project is missing', () => {
      const article = { language: 'en', title: 'My Article' };
      const result = new URLBuilder({ article });
      expect(() => result.parsedArticleURL()).toThrow(TypeError);
    });
    it('should throw an error if the title is missing', () => {
      const article = { language: 'en', project: 'wikipedia' };
      const result = new URLBuilder({ article });
      expect(() => result.parsedArticleURL()).toThrow(TypeError);
    });
    it('should correctly encode page titles as URL parameters', () => {
      const article = { language: 'en', project: 'wikipedia', title: 'Bed Bath & Beyond' };
      const helper = new URLBuilder({ article });
      const expected = 'https://en.wikipedia.org/w/api.php?action=parse&disableeditsection=true&redirects=true&format=json&page=Bed%20Bath%20%26%20Beyond';
      expect(helper.parsedArticleURL()).toEqual(expected);
    });
  });

  describe('#wikiURL', () => {
    it('should create a wikiURL when given a valid article', () => {
      const helper = new URLBuilder({ article: defaults.article });
      expect(helper.wikiURL()).toEqual('https://en.wikipedia.org');
    });
    it('should default the language to `www` if it is missing', () => {
      const article = { project: 'wikipedia' };
      const helper = new URLBuilder({ article });
      expect(helper.wikiURL()).toEqual('https://www.wikipedia.org');
    });
    it('should throw an error if the project is missing', () => {
      const article = { language: 'en', title: 'My Article' };
      const result = new URLBuilder({ article });
      expect(() => result.wikiURL()).toThrow(TypeError);
    });
  });
});
