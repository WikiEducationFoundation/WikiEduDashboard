import { fetchMoreArticles } from '../../app/assets/javascripts/actions/articles_actions';
import { API_FAIL, RECEIVE_MORE_ARTICLES } from '../../app/assets/javascripts/constants';
import { fetchWikidataLabelsForArticles } from '../../app/assets/javascripts/actions/wikidata_actions';

jest.mock('../../app/assets/javascripts/utils/log_error_message');
jest.mock('../../app/assets/javascripts/actions/wikidata_actions', () => ({
  fetchWikidataLabelsForArticles: jest.fn()
}));

const loaded = ids => ids.map(id => ({ id, articles_course_id: id }));
const getState = ids => () => ({ articles: { articles: loaded(ids) } });

const mockResponse = (body, ok = true, status = 200) => {
  global.fetch = jest.fn(() => Promise.resolve({
    ok,
    status,
    json: () => Promise.resolve(body)
  }));
};

describe('fetchMoreArticles', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  it('asks for the page after the highest articles_course_id loaded, whatever the list order', async () => {
    mockResponse({ course: { articles: [] } });
    await fetchMoreArticles('School/Course_(2026)')(jest.fn(), getState([7, 3, 9]));

    const url = global.fetch.mock.calls[0][0];
    expect(url).toContain('after_id=9');
    expect(url).toContain('limit=500');
  });

  it('asks for the first page when nothing is loaded', async () => {
    mockResponse({ course: { articles: [] } });
    await fetchMoreArticles('School/Course_(2026)')(jest.fn(), getState([]));

    expect(global.fetch.mock.calls[0][0]).not.toContain('after_id');
  });

  it('dispatches RECEIVE_MORE_ARTICLES with the page and the page size', async () => {
    const page = loaded([10, 11, 12]);
    mockResponse({ course: { articles: page } });
    const dispatch = jest.fn();
    await fetchMoreArticles('School/Course_(2026)')(dispatch, getState([1, 2]));

    const action = dispatch.mock.calls.map(call => call[0]).find(a => a.type === RECEIVE_MORE_ARTICLES);
    expect(action.data.course.articles).toEqual(page);
    expect(action.pageSize).toBe(500);
    expect(fetchWikidataLabelsForArticles).toHaveBeenCalledWith(page, dispatch);
  });

  it('dispatches API_FAIL and no articles when the request fails', async () => {
    mockResponse({}, false, 500);
    const dispatch = jest.fn();
    await fetchMoreArticles('School/Course_(2026)')(dispatch, getState([1, 2]));

    const types = dispatch.mock.calls.map(call => call[0].type);
    expect(types).toContain(API_FAIL);
    expect(types).not.toContain(RECEIVE_MORE_ARTICLES);
  });
});
