import deepFreeze from 'deep-freeze';
import articles from '../../app/assets/javascripts/reducers/articles';
import { RECEIVE_MORE_ARTICLES } from '../../app/assets/javascripts/constants/articles';
import '../testHelper';

const article = (id, characterSum, extra = {}) => ({
  id,
  articles_course_id: id,
  title: `article_${id}`,
  character_sum: characterSum,
  new_article: false,
  tracked: true,
  language: 'en',
  project: 'wikipedia',
  ...extra
});

const stateWith = (loaded, sort = { sortKey: 'character_sum', key: 'character_sum' }) => {
  const state = {
    ...articles(undefined, { type: null }),
    articles: loaded,
    limit: loaded.length,
    limitReached: false,
    loading: false,
    sort
  };
  return deepFreeze(state);
};

const moreArticles = (page, pageSize = 2) => ({
  type: RECEIVE_MORE_ARTICLES,
  data: { course: { articles: page } },
  pageSize
});

describe('articles reducer: RECEIVE_MORE_ARTICLES', () => {
  test('appends the new page to the loaded articles and updates the limit', () => {
    const state = stateWith([article(1, 30), article(2, 20)]);
    const newState = articles(state, moreArticles([article(3, 10), article(4, 5)]));

    expect(newState.articles.map(a => a.id)).toEqual([1, 2, 3, 4]);
    expect(newState.limit).toBe(4);
  });

  test('re-applies the current sort, so new rows do not land at the bottom', () => {
    const state = stateWith([article(1, 30), article(2, 20)]);
    const newState = articles(state, moreArticles([article(3, 50), article(4, 5)]));

    expect(newState.articles.map(a => a.id)).toEqual([3, 1, 2, 4]);
  });

  test('keeps a reversed sort reversed', () => {
    const state = stateWith([article(2, 20), article(1, 30)], { sortKey: null, key: 'character_sum' });
    const newState = articles(state, moreArticles([article(3, 50), article(4, 5)]));

    expect(newState.articles.map(a => a.id)).toEqual([4, 2, 1, 3]);
  });

  test('adds new rows at the end when no sort is selected', () => {
    const state = stateWith([article(2, 20), article(1, 30)], { sortKey: null, key: null });
    const newState = articles(state, moreArticles([article(3, 50), article(4, 5)]));

    expect(newState.articles.map(a => a.id)).toEqual([2, 1, 3, 4]);
  });

  test('does not duplicate articles that arrive twice', () => {
    const state = stateWith([article(1, 30), article(2, 20)]);
    const newState = articles(state, moreArticles([article(2, 20), article(3, 10)]));

    expect(newState.articles.map(a => a.id)).toEqual([1, 2, 3]);
    expect(newState.limit).toBe(3);
  });

  test('sets limitReached only when a page comes back short', () => {
    const state = stateWith([article(1, 30)]);
    const fullPage = articles(state, moreArticles([article(2, 20), article(3, 10)], 2));
    const shortPage = articles(state, moreArticles([article(2, 20)], 2));

    expect(fullPage.limitReached).toBe(false);
    expect(shortPage.limitReached).toBe(true);
  });
});
