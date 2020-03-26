import { ArticleViewerAPI } from './ArticleViewerAPI';
import URLBuilder from './URLBuilder';
import fetch from 'cross-fetch';

// START: Mock fetch functionality
const htmlReplace = jest.fn(() => true);
const fetchMock = jest.fn(() => {
  return Promise.resolve({
    ok: true,
    json: () => {
      const response = {
        parse: { text: { '*': { replace: htmlReplace } }, pageid: 1 },
        success: true
      };
      return Promise.resolve(response);
    }
  });
});
jest.mock('cross-fetch');
fetch.mockImplementation(fetchMock);
// END: Mock fetch functionality

describe('ArticleViewerAPI', () => {
  let builder;
  beforeEach(() => {
    builder = new URLBuilder({
      article: { language: 'en', project: 'wikipedia', title: 'My Article' },
      users: ['user1', 'user2']
    });
  });

  it('should be able to create a new instance of itself', () => {
    const api = new ArticleViewerAPI({ builder });
    expect(typeof api).toEqual('object');
  });

  describe('.fetchParsedArticle()', () => {
    it('should make a request to the builder.parsedArticleURL', async () => {
      const api = new ArticleViewerAPI({ builder });
      const actual = await api.fetchParsedArticle();

      const expectedURL = `${builder.parsedArticleURL()}&origin=*`;
      const expectedOptions = {
        headers: {
          'Content-Type': 'application/javascript'
        }
      };
      expect(fetchMock).toHaveBeenCalledWith(expectedURL, expectedOptions);
      expect(htmlReplace).toHaveBeenCalled();

      const expectedResponse = {
        articlePageId: 1,
        fetched: true,
        parsedArticle: {
          html: true
        }
      };
      expect(actual).toEqual(expectedResponse);
    });
  });
});
