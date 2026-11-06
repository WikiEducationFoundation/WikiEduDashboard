import '../testHelper';
import { getFilteredArticleFinder } from '../../app/assets/javascripts/selectors';

const EN_WIKI = { language: 'en', project: 'wikipedia' };
// Spanish Wikipedia does not assess its articles, so there are no grades
// recorded for it.
const ES_WIKI = { language: 'es', project: 'wikipedia' };

const article = (title, extra = {}) => ({
  pageid: 1,
  title,
  fetchState: 'PAGEVIEWS_RECEIVED',
  relevanceIndex: 1,
  ...extra
});

const buildState = ({
  wiki = null,
  homeWiki = EN_WIKI,
  articles = {},
  articleQuality = 100,
  minViews = '0'
} = {}) => ({
  articleFinder: {
    wiki,
    home_wiki: homeWiki,
    articles,
    article_quality: articleQuality,
    min_views: minViews
  }
});

const titlesIn = state => Object.keys(getFilteredArticleFinder(state));

describe('getFilteredArticleFinder', () => {
  test('judges a grade by the wiki being searched, not the home wiki', () => {
    // A featured article scores 100 on English Wikipedia, so a filter of 50
    // excludes it. Reading the home wiki instead would find no grades for
    // Spanish Wikipedia and keep the article.
    const state = buildState({
      homeWiki: ES_WIKI,
      wiki: EN_WIKI,
      articles: { Selfie: article('Selfie', { grade: 'FA' }) },
      articleQuality: 50
    });

    expect(titlesIn(state)).toEqual([]);
  });

  test('keeps an article when the wiki being searched has no grades', () => {
    const state = buildState({
      homeWiki: ES_WIKI,
      articles: { Selfie: article('Selfie', { grade: 'FA' }) },
      articleQuality: 50
    });

    expect(() => titlesIn(state)).not.toThrow();
    expect(titlesIn(state)).toEqual(['Selfie']);
  });

  test('excludes an article graded with something the wiki does not use', () => {
    const state = buildState({
      wiki: EN_WIKI,
      articles: { Selfie: article('Selfie', { grade: 'not-a-grade' }) }
    });

    expect(titlesIn(state)).toEqual([]);
  });

  test('keeps an article whose grade is within the quality filter', () => {
    const state = buildState({
      wiki: EN_WIKI,
      articles: { Selfie: article('Selfie', { grade: 'Stub' }) },
      articleQuality: 50
    });

    expect(titlesIn(state)).toEqual(['Selfie']);
  });

  test('still excludes an article below the minimum view count', () => {
    const state = buildState({
      wiki: EN_WIKI,
      articles: { Selfie: article('Selfie', { pageviews: 5 }) },
      minViews: '10'
    });

    expect(titlesIn(state)).toEqual([]);
  });
});
