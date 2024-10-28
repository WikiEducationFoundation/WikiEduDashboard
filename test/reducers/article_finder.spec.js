import articleFinder from '../../app/assets/javascripts/reducers/article_finder';
import {
  UPDATE_FINDER_FIELD,
  RECEIVE_CATEGORY_RESULTS,
  CLEAR_FINDER_STATE,
  RECEIVE_ARTICLE_PAGEVIEWS,
  RECEIVE_ARTICLE_PAGEASSESSMENT,
  SORT_ARTICLE_FINDER,
  RECEIVE_KEYWORD_RESULTS,
  INITIATE_SEARCH,
  CLEAR_RESULTS,
} from '../../app/assets/javascripts/constants/article_finder';

describe('articleFinder reducer', () => {
  const initialState = {
    articles: {},
    search_type: 'keyword',
    search_term: '',
    min_views: '0',
    article_quality: 100,
    loading: false,
    fetchState: 'PAGEVIEWS_RECEIVED',
    sort: {
      sortKey: null,
      key: null,
    },
    continue_results: false,
    offset: 0,
    cmcontinue: '',
    home_wiki: {
      language: 'en',
      project: 'wikipedia',
    },
    lastRelevanceIndex: 0,
  };

  it('should return the initial state when given an undefined state and action', () => {
    expect(articleFinder(undefined, {})).toEqual(initialState);
  });

  it('should handle UPDATE_FINDER_FIELD', () => {
    const action = {
      type: UPDATE_FINDER_FIELD,
      data: { key: 'search_term', value: 'JavaScript' },
    };
    const expectedState = {
      ...initialState,
      search_term: 'JavaScript',
    };
    expect(articleFinder(initialState, action)).toEqual(expectedState);
  });

  it('should handle SORT_ARTICLE_FINDER', () => {
    const stateWithArticles = {
      ...initialState,
      articles: {
        Article1: { title: 'Article1', pageviews: 100 },
        Article2: { title: 'Article2', pageviews: 50 },
      },
    };
    const action = {
      type: SORT_ARTICLE_FINDER,
      key: 'pageviews',
      desc: true,
    };
    const sortedArticles = {
      Article1: { title: 'Article1', pageviews: 100 },
      Article2: { title: 'Article2', pageviews: 50 },
    };
    const expectedState = {
      ...stateWithArticles,
      articles: sortedArticles,
      sort: {
        sortKey: null,
        key: 'pageviews',
      },
    };
    expect(articleFinder(stateWithArticles, action)).toEqual(expectedState);
  });

  it('should handle CLEAR_FINDER_STATE', () => {
    const modifiedState = { ...initialState, search_term: 'Science' };
    const action = { type: CLEAR_FINDER_STATE };
    expect(articleFinder(modifiedState, action)).toEqual(initialState);
  });

  it('should handle INITIATE_SEARCH', () => {
    const action = { type: INITIATE_SEARCH };
    const expectedState = {
      ...initialState,
      loading: true,
      fetchState: 'ARTICLES_LOADING',
    };
    expect(articleFinder(initialState, action)).toEqual(expectedState);
  });

  it('should handle RECEIVE_CATEGORY_RESULTS', () => {
    const action = {
      type: RECEIVE_CATEGORY_RESULTS,
      data: {
        query: {
          categorymembers: [
            { title: 'Article1', pageid: 1, ns: 0 },
            { title: 'Article2', pageid: 2, ns: 0 },
          ],
        },
        continue: { cmcontinue: 'continueToken' },
      },
    };
    const expectedState = {
      ...initialState,
      articles: {
        Article1: { pageid: 1, ns: 0, fetchState: 'TITLE_RECEIVED', title: 'Article1', relevanceIndex: 1 },
        Article2: { pageid: 2, ns: 0, fetchState: 'TITLE_RECEIVED', title: 'Article2', relevanceIndex: 2 },
      },
      continue_results: true,
      cmcontinue: 'continueToken',
      fetchState: 'TITLE_RECEIVED',
      lastRelevanceIndex: 50,
    };
    expect(articleFinder(initialState, action)).toEqual(expectedState);
  });

  it('should handle RECEIVE_KEYWORD_RESULTS', () => {
    const action = {
      type: RECEIVE_KEYWORD_RESULTS,
      data: {
        query: {
          search: [
            { title: 'Article3', pageid: 3, ns: 0 },
            { title: 'Article4', pageid: 4, ns: 0 },
          ],
        },
        continue: { sroffset: 10 },
      },
    };
    const expectedState = {
      ...initialState,
      articles: {
        Article3: { pageid: 3, ns: 0, fetchState: 'TITLE_RECEIVED', title: 'Article3', relevanceIndex: 1 },
        Article4: { pageid: 4, ns: 0, fetchState: 'TITLE_RECEIVED', title: 'Article4', relevanceIndex: 2 },
      },
      continue_results: true,
      offset: 10,
      fetchState: 'TITLE_RECEIVED',
      lastRelevanceIndex: 50,
    };
    expect(articleFinder(initialState, action)).toEqual(expectedState);
  });

  it('should handle RECEIVE_ARTICLE_PAGEVIEWS', () => {
    const stateWithArticles = {
      ...initialState,
      articles: {
        Article1: { title: 'Article1', pageviews: 0, fetchState: 'TITLE_RECEIVED' },
      },
    };
    const action = {
      type: RECEIVE_ARTICLE_PAGEVIEWS,
      data: [
        { title: 'Article1', pageviews: { day1: 20, day2: 30 } },
      ],
    };
    const expectedState = {
      ...stateWithArticles,
      articles: {
        Article1: { title: 'Article1', pageviews: 25, fetchState: 'PAGEVIEWS_RECEIVED' },
      },
      fetchState: 'PAGEVIEWS_RECEIVED',
    };
    expect(articleFinder(stateWithArticles, action)).toEqual(expectedState);
  });

  it('should handle RECEIVE_ARTICLE_PAGEASSESSMENT', () => {
    const stateWithArticles = {
      ...initialState,
      articles: {
        Article1: { title: 'Article1', fetchState: 'TITLE_RECEIVED' },
      },
    };
    const action = {
      type: RECEIVE_ARTICLE_PAGEASSESSMENT,
      data: [
        { title: 'Article1', pageassessments: { class: 'B' } },
      ],
    };
    const expectedState = {
      ...stateWithArticles,
      articles: {
        Article1: { title: 'Article1', grade: 'B', fetchState: 'PAGEASSESSMENT_RECEIVED' },
      },
      fetchState: 'PAGEASSESSMENT_RECEIVED',
    };
    expect(articleFinder(stateWithArticles, action)).toEqual(expectedState);
  });

  it('should handle CLEAR_RESULTS', () => {
    const modifiedState = { ...initialState, articles: { Article1: { title: 'Article1' } } };
    const action = { type: CLEAR_RESULTS };
    const expectedState = { ...initialState };
    expect(articleFinder(modifiedState, action)).toEqual(expectedState);
  });
});
