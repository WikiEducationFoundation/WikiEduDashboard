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
