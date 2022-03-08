import deepFreeze from 'deep-freeze';
import articles from '../../app/assets/javascripts/reducers/articles';
import {
  RECEIVE_ARTICLES,
  SORT_ARTICLES,
  SET_PROJECT_FILTER,
  SET_NEWNESS_FILTER
} from '../../app/assets/javascripts/constants/articles';
import '../testHelper';

const articles_array = [
  {
    id: 1,
    title: 'articles_1',
    new_article: false,
    language: 'us',
    project: 'wikidata'
  },
  {
    id: 3,
    title: 'articles_3',
    new_article: true,
    language: 'es',
    project: 'wikipedia'
  },
  {
    id: 2,
    title: 'articles_2',
    new_article: false,
    language: 'es',
    project: 'wikipedia'
  }
];

describe('articles reducer', () => {
  test(
    'should return initial state when no action nor state is provided',
    () => {
      const newState = articles(undefined, { type: null });
      expect(Array.isArray(newState.articles)).toBe(true);
      expect(newState.limit).toBe(500);
      expect(newState.limitReached).toBe(false);
      expect(typeof newState.sort).toBe('object');
      expect(newState.sort.key).toBeNull();
      expect(newState.sort.sortKey).toBeNull();
      expect(Array.isArray(newState.wikis)).toBe(true);
      expect(newState.wikiFilter).toMatchObject({ project: 'all' });
      expect(newState.newnessFilter).toBe('both');
      expect(newState.loading).toBe(true);
      expect(newState.newnessFilterEnabled).toBe(false);
    }
  );

  test('receive articles and remove duplicates with RECEIVE_ARTICLES', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_ARTICLES,
      data: {
        course: {
          articles: articles_array
        }
      },
      limit: 5
    };

    const newState = articles(initialState, mockedAction);
    expect(newState.limit).toBe(5);
    expect(newState.limitReached).toBe(true);
    expect(newState.wikis).toHaveLength(2);
    expect(newState.newnessFilterEnabled).toBe(true);
    expect(newState.loading).toBe(false);
  });

  test('sorts articles via SORT_ARTICLES', () => {
    const initialState = { articles: articles_array, sort: { sorKey: null } };
    deepFreeze(initialState);
    const mockedAction = {
      type: SORT_ARTICLES,
      key: 'id'
    };

    const newState = articles(initialState, mockedAction);
    expect(newState.sort.key).toBe('id');
    expect(newState.articles[0].id).toBe(1);
    expect(newState.articles[1].id).toBe(2);
    expect(newState.articles[2].id).toBe(3);
  });

  test('sets filter conditionally with SET_PROJECT_FILTER', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: SET_PROJECT_FILTER,
      wiki: {
        project: 'all',
        language: 'us'
      }
    };

    const state = articles(initialState, mockedAction);
    expect(state.wikiFilter).toMatchObject({ project: 'all' });


    const newMockedAction = {
      type: SET_PROJECT_FILTER,
      wiki: {
        project: '',
        language: 'us'
      }
    };
    const newState = articles(initialState, newMockedAction);
    expect(typeof newState.wikiFilter).toBe('object');
  });

  test(
    'returns newnessFilter attribute with action value via SET_NEWNESS_FILTER',
    () => {
      const initialState = {};
      deepFreeze(initialState);
      const mockedAction = {
        type: SET_NEWNESS_FILTER,
        newness: 'new'
      };

      const newState = articles(initialState, mockedAction);
      expect(newState.newnessFilter).toBe('new');
    }
  );
});
