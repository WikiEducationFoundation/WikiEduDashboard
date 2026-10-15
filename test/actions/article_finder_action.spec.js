import '../testHelper';
import * as utils from '../../app/assets/javascripts/utils/article_finder_utils';
import { fetchKeywordResults } from '../../app/assets/javascripts/actions/article_finder_action';
import { API_FAIL, END_SEARCH } from '../../app/assets/javascripts/constants';

// The later rounds of requests in a search are fire-and-forget, so give their
// promise chains a chance to settle before asserting.
const flushPromises = async () => {
  for (let i = 0; i < 20; i += 1) {
    await Promise.resolve();
  }
};

// Spanish Wikipedia has neither page assessments nor completeness scores, so a
// search there is just the keyword query followed by page views. That keeps
// these tests to the two rounds of requests they are about.
const wiki = { language: 'es', project: 'wikipedia' };

// Enough results to be split into more than one page views request, which are
// chunked five at a time.
const tenResults = Array.from({ length: 10 }, (_, i) => ({
  pageid: i + 1,
  ns: 0,
  title: `Article ${i + 1}`
}));

const dispatchedTypes = dispatch => dispatch.mock.calls.map(([action]) => action.type);
const countOf = (dispatch, type) => dispatchedTypes(dispatch).filter(t => t === type).length;

describe('fetchKeywordResults', () => {
  let dispatch;
  const getState = () => ({ articleFinder: { sort: { sortKey: null, key: null } } });

  beforeEach(() => {
    dispatch = jest.fn();
  });

  afterEach(() => {
    if (utils.queryUrl.restore) utils.queryUrl.restore();
  });

  test('ends the search when the keyword query fails', async () => {
    sinon.stub(utils, 'queryUrl').rejects(new Error('network unavailable'));

    await fetchKeywordResults('climate', wiki)(dispatch, getState);
    await flushPromises();

    // Without this the loading indicators run and the search button stays
    // disabled until the page is reloaded.
    expect(dispatchedTypes(dispatch)).toContain(END_SEARCH);
    expect(countOf(dispatch, API_FAIL)).toBe(1);
  });

  test('reports a failed round of requests once, not once per request', async () => {
    sinon.stub(utils, 'queryUrl').callsFake((url, query) => {
      if (query.list === 'search') {
        return Promise.resolve({ query: { search: tenResults } });
      }
      return Promise.reject(new Error('page views unavailable'));
    });

    await fetchKeywordResults('climate', wiki)(dispatch, getState);
    await flushPromises();

    expect(countOf(dispatch, API_FAIL)).toBe(1);
  });

  test('ends the search once the page views have been requested', async () => {
    sinon.stub(utils, 'queryUrl').callsFake((url, query) => {
      if (query.list === 'search') {
        return Promise.resolve({ query: { search: tenResults } });
      }
      return Promise.resolve({ query: { pages: {} } });
    });

    await fetchKeywordResults('climate', wiki)(dispatch, getState);
    await flushPromises();

    expect(dispatchedTypes(dispatch)).toContain(END_SEARCH);
    expect(countOf(dispatch, API_FAIL)).toBe(0);
  });
});
