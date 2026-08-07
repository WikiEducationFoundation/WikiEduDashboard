import { AuthorshipAPI } from './AuthorshipAPI';
import AuthorshipURLBuilder from './AuthorshipURLBuilder';

// START: Mock fetch functionality
const fetchMock = jest.fn(() => {
  return Promise.resolve({
    ok: true,
    json: () => Promise.resolve({ query: { users: [{ name: 'user1', userid: 1 }] } })
  });
});
global.fetch = fetchMock;
// END: Mock fetch functionality

describe('AuthorshipAPI', () => {
  let builder;
  beforeEach(() => {
    fetchMock.mockClear();
    builder = new AuthorshipURLBuilder({
      article: { language: 'en', project: 'wikipedia', title: 'My Article' },
      users: ['user1', 'user2']
    });
  });

  it('should be able to create a new instance of itself', () => {
    const api = new AuthorshipAPI({ builder });
    expect(typeof api).toEqual('object');
  });

  describe('.fetchWhocolorHtml()', () => {
    it('should return the payload tokens alongside the processed html', async () => {
      fetchMock.mockImplementationOnce(() => Promise.resolve({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          extended_html: '<p><a href="/wiki/Bears">Bears</a></p>',
          tokens: [[0, 'bears', 1, [], [], '48311939', 0]]
        })
      }));
      const api = new AuthorshipAPI({ builder });
      const actual = await api.fetchWhocolorHtml(1253430861);

      // The tokens carry the per-token authorship for the requested revision, so
      // the caller never has to ask a second endpoint which editors are present.
      expect(actual.tokens).toEqual([[0, 'bears', 1, [], [], '48311939', 0]]);
      expect(actual.html).toEqual('<p><a href="https://en.wikipedia.org/wiki/Bears">Bears</a></p>');
    });

    it('should return a failure marker when the payload has no html', async () => {
      fetchMock.mockImplementationOnce(() => Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ success: true, tokens: [] })
      }));
      const api = new AuthorshipAPI({ builder });

      expect(await api.fetchWhocolorHtml(1253430861)).toEqual({ whocolorFailed: true });
    });
  });

  describe('.fetchUserIds()', () => {
    it('should make a request to the builder.wikiUserQueryURL', async () => {
      const api = new AuthorshipAPI({ builder });
      const actual = await api.fetchUserIds();

      const expectedURL = `${builder.wikiUserQueryURL()}&origin=*`;
      const expectedOptions = {
        headers: {
          'Content-Type': 'application/javascript'
        }
      };
      expect(fetchMock).toHaveBeenCalledWith(expectedURL, expectedOptions);
      expect(actual).toEqual({ query: { users: [{ name: 'user1', userid: 1 }] } });
    });
  });
});
