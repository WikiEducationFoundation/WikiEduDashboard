import '../testHelper';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import reducer from '../../app/assets/javascripts/reducers';
import * as utils from '../../app/assets/javascripts/utils/article_finder_utils';
import { fetchKeywordResults, fetchCategoryResults, clearResults } from '../../app/assets/javascripts/actions/article_finder_action';
import { API_FAIL, END_SEARCH } from '../../app/assets/javascripts/constants';

// The later rounds of a search are fire-and-forget, so give their promise
// chains a chance to settle before asserting.
const flushPromises = async () => {
  for (let i = 0; i < 30; i += 1) {
    await Promise.resolve();
  }
};

// Spanish Wikipedia has neither page assessments nor completeness scores, so a
// search there is the keyword or category query followed by page views.
const wiki = { language: 'es', project: 'wikipedia' };

// Ten results are split into two page views requests, which are chunked five
// at a time.
const results = (prefix, firstId = 1) => Array.from({ length: 10 }, (_, i) => ({
  pageid: firstId + i,
  ns: 0,
  title: `${prefix} ${i + 1}`
}));

const pageviewsFor = articles => ({
  query: {
    pages: Object.fromEntries(articles.map(article => [
      article.pageid,
      { pageid: article.pageid, title: article.title, pageviews: { '2026-10-01': 5 } }
    ]))
  }
});

// The page views response for whichever of `articles` a request asked about.
const pageviewsRequested = (query, articles) => {
  const ids = query.pageids.split('|').map(Number);
  return pageviewsFor(articles.filter(article => ids.includes(article.pageid)));
};

// A promise whose outcome the test decides.
const deferred = () => {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
};

describe('article finder searches', () => {
  let store;
  let dispatched;

  beforeEach(() => {
    dispatched = [];
    const record = () => next => (action) => {
      dispatched.push(action.type);
      return next(action);
    };
    store = createStore(reducer, applyMiddleware(thunk, record));
  });

  afterEach(() => {
    if (utils.queryUrl.restore) utils.queryUrl.restore();
  });

  const finder = () => store.getState().articleFinder;
  const countOf = type => dispatched.filter(t => t === type).length;

  describe('when the first query fails', () => {
    beforeEach(() => {
      sinon.stub(utils, 'queryUrl').rejects(new Error('network unavailable'));
    });

    it('ends a keyword search with nothing to show', async () => {
      await store.dispatch(fetchKeywordResults('climate', wiki));
      await flushPromises();

      expect(finder().loading).toBe(false);
      expect(finder().searchFailed).toBe(true);
      expect(countOf(API_FAIL)).toBe(1);
      expect(countOf(END_SEARCH)).toBe(1);
    });

    it('ends a category search with nothing to show', async () => {
      await store.dispatch(fetchCategoryResults('Climate', wiki));
      await flushPromises();

      expect(finder().loading).toBe(false);
      expect(finder().searchFailed).toBe(true);
      expect(countOf(API_FAIL)).toBe(1);
      expect(countOf(END_SEARCH)).toBe(1);
    });
  });

  describe('when a later round fails', () => {
    beforeEach(() => {
      sinon.stub(utils, 'queryUrl').callsFake((url, query) => {
        if (query.list === 'search') {
          return Promise.resolve({ query: { search: results('Article') } });
        }
        return Promise.reject(new Error('page views unavailable'));
      });
    });

    it('reports the round once, not once per request', async () => {
      await store.dispatch(fetchKeywordResults('climate', wiki));
      await flushPromises();

      expect(countOf(API_FAIL)).toBe(1);
    });

    it('still finishes the search, which did find articles', async () => {
      await store.dispatch(fetchKeywordResults('climate', wiki));
      await flushPromises();

      expect(finder().fetchState).toBe('PAGEVIEWS_RECEIVED');
      expect(finder().searchFailed).toBe(false);
      expect(Object.keys(finder().articles)).toHaveLength(10);
    });
  });

  it('finishes a search once its page views have arrived', async () => {
    const articles = results('Article');
    sinon.stub(utils, 'queryUrl').callsFake((url, query) => {
      if (query.list === 'search') {
        return Promise.resolve({ query: { search: articles } });
      }
      return Promise.resolve(pageviewsRequested(query, articles));
    });

    await store.dispatch(fetchKeywordResults('climate', wiki));
    await flushPromises();

    expect(countOf(END_SEARCH)).toBe(1);
    expect(countOf(API_FAIL)).toBe(0);
    expect(finder().articles['Article 1'].pageviews).toBe(5);
  });

  // "More Results" continues the current search rather than starting a new
  // one, so a failure there must not throw away the page already loaded.
  describe('when the request for more results fails', () => {
    const firstPage = results('Article');

    beforeEach(() => {
      sinon.stub(utils, 'queryUrl').callsFake((url, query) => {
        const nextPage = query.sroffset > 0 || query.cmcontinue;
        if (nextPage) {
          return Promise.reject(new Error('next page unavailable'));
        }
        if (query.list === 'search') {
          return Promise.resolve({ query: { search: firstPage }, continue: { sroffset: 50 } });
        }
        if (query.list === 'categorymembers') {
          return Promise.resolve({ query: { categorymembers: firstPage }, continue: { cmcontinue: 'next' } });
        }
        return Promise.resolve(pageviewsRequested(query, firstPage));
      });
    });

    const expectFirstPageKept = () => {
      expect(Object.keys(finder().articles)).toHaveLength(10);
      expect(finder().searchFailed).toBe(false);
      expect(finder().fetchState).toBe('PAGEVIEWS_RECEIVED');
      expect(countOf(API_FAIL)).toBe(1);
    };

    it('keeps the keyword results already loaded', async () => {
      await store.dispatch(fetchKeywordResults('climate', wiki));
      await flushPromises();
      await store.dispatch(fetchKeywordResults('climate', wiki, 50, true));
      await flushPromises();

      expectFirstPageKept();
    });

    it('keeps the category results already loaded', async () => {
      await store.dispatch(fetchCategoryResults('Climate', wiki));
      await flushPromises();
      await store.dispatch(fetchCategoryResults('Climate', wiki, 'next', true));
      await flushPromises();

      expectFirstPageKept();
    });
  });

  // A search the user abandons, by changing wiki or searching again, keeps
  // running. Whatever it dispatches after that must not touch the search that
  // replaced it.
  describe('a search abandoned by a wiki change', () => {
    let alphaKeyword;
    let alphaPageviews;
    let betaKeyword;
    let betaPageviews;

    beforeEach(() => {
      alphaKeyword = deferred();
      alphaPageviews = deferred();
      betaKeyword = deferred();
      betaPageviews = deferred();
      sinon.stub(utils, 'queryUrl').callsFake((url, query) => {
        if (query.list === 'search') {
          return query.srsearch === 'alpha' ? alphaKeyword.promise : betaKeyword.promise;
        }
        // Alpha's articles have ids below 100, beta's above.
        return Number(query.pageids.split('|')[0]) < 100 ? alphaPageviews.promise : betaPageviews.promise;
      });
    });

    const alpha = results('Alpha', 1);
    const beta = results('Beta', 101);

    it('does not add its results to the cleared store', async () => {
      store.dispatch(fetchKeywordResults('alpha', wiki));
      await flushPromises();
      store.dispatch(clearResults());

      alphaKeyword.resolve({ query: { search: alpha } });
      await flushPromises();

      expect(finder().articles).toEqual({});
      expect(finder().loading).toBe(false);
    });

    it('does not end the search that replaced it while its query is pending', async () => {
      store.dispatch(fetchKeywordResults('alpha', wiki));
      alphaKeyword.resolve({ query: { search: alpha } });
      await flushPromises();
      store.dispatch(clearResults());
      store.dispatch(fetchKeywordResults('beta', wiki));
      await flushPromises();
      expect(finder().loading).toBe(true);

      alphaPageviews.resolve(pageviewsFor(alpha));
      await flushPromises();

      expect(finder().loading).toBe(true);
    });

    it('does not move the new search\'s articles on before their data arrives', async () => {
      store.dispatch(fetchKeywordResults('alpha', wiki));
      alphaKeyword.resolve({ query: { search: alpha } });
      await flushPromises();
      store.dispatch(clearResults());
      store.dispatch(fetchKeywordResults('beta', wiki));
      betaKeyword.resolve({ query: { search: beta } });
      await flushPromises();
      expect(finder().articles['Beta 1'].fetchState).toBe('TITLE_RECEIVED');

      alphaPageviews.resolve(pageviewsFor(alpha));
      await flushPromises();

      expect(finder().articles['Beta 1'].fetchState).toBe('TITLE_RECEIVED');
      expect(finder().fetchState).toBe('TITLE_RECEIVED');
    });
  });
});
