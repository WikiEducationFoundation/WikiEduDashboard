import { fetchArticles } from '../../app/assets/javascripts/actions/articles_actions';
import { RECEIVE_ARTICLES } from '../../app/assets/javascripts/constants';

jest.mock('../../app/assets/javascripts/utils/log_error_message');
jest.mock('../../app/assets/javascripts/actions/wikidata_actions', () => ({
  fetchWikidataLabelsForArticles: jest.fn()
}));

// A fake server holding `total` articles that understands the limit and
// after_id parameters of articles.json.
const mockServer = (total) => {
  const all = Array.from({ length: total }, (_, i) => ({ id: i + 1, articles_course_id: i + 1 }));
  global.fetch = jest.fn((url) => {
    const params = new URL(url).searchParams;
    const limit = Number(params.get('limit'));
    const afterId = Number(params.get('after_id') || 0);
    const rows = all.filter(article => article.articles_course_id > afterId).slice(0, limit);
    return Promise.resolve({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ course: { articles: rows } })
    });
  });
};

describe('fetchArticles', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  const receivedAction = async (limit) => {
    const dispatch = jest.fn();
    await fetchArticles('School/Course_(2026)', limit)(dispatch);
    return dispatch.mock.calls.map(call => call[0]).find(action => action.type === RECEIVE_ARTICLES);
  };

  it('requests articles in pages of 500 and combines them', async () => {
    mockServer(1200);
    const action = await receivedAction(1200);

    expect(global.fetch).toHaveBeenCalledTimes(3);
    expect(action.limit).toBe(1200);
    expect(action.data.course.articles).toHaveLength(1200);
    const ids = action.data.course.articles.map(article => article.articles_course_id);
    expect(new Set(ids).size).toBe(1200);
  });

  it('sends the last articles_course_id as the cursor for the next page', async () => {
    mockServer(1200);
    await receivedAction(1200);

    expect(global.fetch.mock.calls[0][0]).not.toContain('after_id');
    expect(global.fetch.mock.calls[1][0]).toContain('after_id=500');
    expect(global.fetch.mock.calls[2][0]).toContain('after_id=1000');
  });

  it('stops when the course has fewer articles than requested', async () => {
    mockServer(700);
    const action = await receivedAction(1000);

    expect(global.fetch).toHaveBeenCalledTimes(2);
    expect(action.data.course.articles).toHaveLength(700);
  });

  it('can list more articles than the old 5000 cap', async () => {
    mockServer(6000);
    const action = await receivedAction(6000);

    expect(global.fetch).toHaveBeenCalledTimes(12);
    expect(action.data.course.articles).toHaveLength(6000);
  });
});
