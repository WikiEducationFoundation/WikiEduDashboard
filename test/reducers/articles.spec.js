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
  it('should return initial state when no action nor state is provided', () => {
    const newState = articles(undefined, { type: null });
    expect(newState.articles).to.be.an('array');
    expect(newState.limit).to.eq(500);
    expect(newState.limitReached).to.eq(false);
    expect(newState.sort).to.be.an('object');
    expect(newState.sort.key).to.eq(null);
    expect(newState.sort.sortKey).to.eq(null);
    expect(newState.wikis).to.be.an('array');
    expect(newState.wikiFilter).to.eq(null);
    expect(newState.newnessFilter).to.eq(null);
    expect(newState.loading).to.eq(true);
    expect(newState.newnessFilterEnabled).to.eq(false);
  });

  it('receive articles and remove duplicates with RECEIVE_ARTICLES', () => {
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
    expect(newState.limit).to.eq(5);
    expect(newState.limitReached).to.eq(true);
    expect(newState.wikis).to.have.length(2);
    expect(newState.newnessFilterEnabled).to.eq(true);
    expect(newState.loading).to.eq(false);
  });

  it('sorts articles via SORT_ARTICLES', () => {
    const initialState = { articles: articles_array, sort: { sorKey: null } };
    deepFreeze(initialState);
    const mockedAction = {
      type: SORT_ARTICLES,
      key: 'id'
    };

    const newState = articles(initialState, mockedAction);
    expect(newState.sort.key).to.eq('id');
    expect(newState.articles[0].id).to.eq(1);
    expect(newState.articles[1].id).to.eq(2);
    expect(newState.articles[2].id).to.eq(3);
  });

  it('sets filter conditionally with SET_PROJECT_FILTER', () => {
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
    expect(state.wikiFilter).to.eq(null);

    const newMockedAction = {
      type: SET_PROJECT_FILTER,
      wiki: {
        project: '',
        language: 'us'
      }
    };
    const newState = articles(initialState, newMockedAction);
    expect(newState.wikiFilter).to.be.an('object');
  });

  it('returns newnessFilter attribute with action value via SET_NEWNESS_FILTER', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: SET_NEWNESS_FILTER,
      newness: 'new'
    };

    const newState = articles(initialState, mockedAction);
    expect(newState.newnessFilter).to.eq('new');
  });
});
