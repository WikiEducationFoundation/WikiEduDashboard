import deepFreeze from 'deep-freeze';
import articleFinder from '../../app/assets/javascripts/reducers/article_finder';
import {
  INITIATE_SEARCH,
  CLEAR_RESULTS,
  CLEAR_FINDER_STATE,
  END_SEARCH,
  RECEIVE_ARTICLE_PAGEVIEWS,
  RECEIVE_ARTICLE_PAGEASSESSMENT,
  RECEIVE_ARTICLE_REVISION,
  RECEIVE_ARTICLE_REVISIONSCORE
} from '../../app/assets/javascripts/constants/article_finder';
import '../testHelper';

const searching = articles => deepFreeze({
  articles,
  loading: false,
  fetchState: 'TITLE_RECEIVED',
  sort: { sortKey: null, key: null }
});

const titleReceived = (title, extra = {}) => ({
  pageid: 1,
  ns: 0,
  title,
  fetchState: 'TITLE_RECEIVED',
  relevanceIndex: 1,
  ...extra
});

describe('article finder reducer', () => {
  describe('receiving data for an article that is not in the results', () => {
    // A response can name an article the store no longer holds: the user has
    // started another search or changed wiki while the request was in flight,
    // or MediaWiki has normalized the title we asked about.
    const unknown = searching({});

    test('skips page views instead of throwing', () => {
      const action = {
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data: { 1: { title: 'Climate change', pageviews: { '2026-01-01': 10 } } }
      };

      expect(() => articleFinder(unknown, action)).not.toThrow();
      expect(articleFinder(unknown, action).articles).toEqual({});
    });

    test('skips an assessment instead of throwing', () => {
      const action = {
        type: RECEIVE_ARTICLE_PAGEASSESSMENT,
        data: { 1: { title: 'Climate change', pageassessments: { Physics: { class: 'B' } } } }
      };

      expect(() => articleFinder(unknown, action)).not.toThrow();
      expect(articleFinder(unknown, action).articles).toEqual({});
    });

    test('skips a revision instead of throwing', () => {
      const action = {
        type: RECEIVE_ARTICLE_REVISION,
        data: { 1: { title: 'Climate change', revisions: [{ revid: 99 }] } }
      };

      expect(() => articleFinder(unknown, action)).not.toThrow();
      expect(articleFinder(unknown, action).articles).toEqual({});
    });
  });

  describe('receiving incomplete data', () => {
    test('records no views for a page the API returned none for', () => {
      const state = searching({ 'Climate change': titleReceived('Climate change') });
      const action = {
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data: { 1: { title: 'Climate change' } }
      };

      const newState = articleFinder(state, action);
      expect(newState.articles['Climate change'].pageviews).toBe(0);
      expect(newState.articles['Climate change'].fetchState).toBe('PAGEVIEWS_RECEIVED');
    });

    test('skips a page that has no revisions, such as one deleted since the search', () => {
      const state = searching({ 'Climate change': titleReceived('Climate change') });
      const action = {
        type: RECEIVE_ARTICLE_REVISION,
        data: { 1: { title: 'Climate change' } }
      };

      const newState = articleFinder(state, action);
      expect(newState.articles['Climate change'].revid).toBeUndefined();
    });

    test('skips a score whose revision belongs to no article in the results', () => {
      const state = searching({ 'Climate change': titleReceived('Climate change', { revid: 1 }) });
      const action = {
        type: RECEIVE_ARTICLE_REVISIONSCORE,
        data: { data: { 999: {} }, language: 'en', project: 'wikipedia' }
      };

      expect(() => articleFinder(state, action)).not.toThrow();
      expect(articleFinder(state, action).articles['Climate change'].revScore).toBeUndefined();
    });
  });

  describe('averaging page views', () => {
    test('records the mean of the daily counts', () => {
      const state = searching({ 'Climate change': titleReceived('Climate change') });
      const action = {
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data: {
          1: {
            title: 'Climate change',
            pageviews: { '2026-01-01': 10, '2026-01-02': 20 }
          }
        }
      };

      expect(articleFinder(state, action).articles['Climate change'].pageviews).toBe(15);
    });
  });

  describe('END_SEARCH', () => {
    test('stops the loading indicators', () => {
      const state = deepFreeze({
        articles: {},
        loading: true,
        fetchState: 'ARTICLES_LOADING',
        sort: { sortKey: null, key: null }
      });

      const newState = articleFinder(state, { type: END_SEARCH });
      expect(newState.loading).toBe(false);
      expect(newState.fetchState).toBe('PAGEVIEWS_RECEIVED');
    });

    test('moves articles still waiting for data to the final state', () => {
      const state = searching({
        'Climate change': titleReceived('Climate change'),
        'Global warming': titleReceived('Global warming', { fetchState: 'PAGEASSESSMENT_RECEIVED', grade: 'B' })
      });

      const { articles } = articleFinder(state, { type: END_SEARCH });
      expect(articles['Climate change'].fetchState).toBe('PAGEVIEWS_RECEIVED');
      expect(articles['Global warming'].fetchState).toBe('PAGEVIEWS_RECEIVED');
    });

    test('keeps the data articles already have', () => {
      const state = searching({
        'Climate change': titleReceived('Climate change', {
          fetchState: 'PAGEVIEWS_RECEIVED',
          grade: 'B',
          pageviews: 15
        })
      });

      const { articles } = articleFinder(state, { type: END_SEARCH });
      expect(articles['Climate change']).toEqual(state.articles['Climate change']);
    });

    test('records that the search ended because its first query failed', () => {
      const state = searching({});

      expect(articleFinder(state, { type: END_SEARCH, failed: true }).searchFailed).toBe(true);
      expect(articleFinder(state, { type: END_SEARCH }).searchFailed).toBe(false);
    });

    test('does not count a failure as the search failing when results are already loaded', () => {
      const state = searching({ 'Climate change': titleReceived('Climate change') });

      expect(articleFinder(state, { type: END_SEARCH, failed: true }).searchFailed).toBe(false);
    });
  });

  describe('telling searches apart', () => {
    const state = deepFreeze({ ...searching({}), searchId: 4, searchFailed: true });

    test('a new search gets a new id and a clean slate', () => {
      const newState = articleFinder(state, { type: INITIATE_SEARCH });
      expect(newState.searchId).toBe(5);
      expect(newState.searchFailed).toBe(false);
    });

    test('clearing the results also moves on to a new id', () => {
      const newState = articleFinder(state, { type: CLEAR_RESULTS });
      expect(newState.searchId).toBe(5);
      expect(newState.searchFailed).toBe(false);
    });

    test('resetting the finder never reuses an id', () => {
      expect(articleFinder(state, { type: CLEAR_FINDER_STATE }).searchId).toBe(5);
    });
  });
});
