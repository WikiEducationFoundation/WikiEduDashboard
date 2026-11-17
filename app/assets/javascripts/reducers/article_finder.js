import { cloneDeep, forEach, reduce, find, isEmpty } from 'lodash-es';
import { extractClassGrade } from '../utils/article_finder_utils.js';
import { sortByKey } from '../utils/model_utils';
import { LiftwingWeights } from '../utils/article_finder_language_mappings.js';
import { UPDATE_FINDER_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE,
  RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT,
  RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, RECEIVE_KEYWORD_RESULTS, INITIATE_SEARCH, END_SEARCH, CLEAR_RESULTS } from '../constants';

const initialState = {
  articles: {},
  search_type: 'keyword',
  search_term: '',
  min_views: '0',
  article_quality: 100,
  loading: false,
  fetchState: 'PAGEVIEWS_RECEIVED',
  // Identifies the current search. Requests from an earlier search can still
  // be in flight after a new one starts or the results are cleared, so the
  // actions compare this with the id they began under and drop anything that
  // no longer belongs. It only ever increases, so an id is never reused.
  searchId: 0,
  // True when a query failed and there is nothing to show, as opposed to a
  // search that found no articles. A failed "More Results" request leaves the
  // results already loaded in place, so it does not count.
  searchFailed: false,
  sort: {
    sortKey: null,
    key: null,
  },
  continue_results: false,
  offset: 0,
  cmcontinue: '',
  home_wiki: {
    language: 'en',
    project: 'wikipedia'
  },
  lastRelevanceIndex: 0,
};

export default function articleFinder(state = initialState, action) {
  switch (action.type) {
    case UPDATE_FINDER_FIELD: {
      const newState = { ...state };
      newState[action.data.key] = action.data.value;
      return newState;
    }
    case SORT_ARTICLE_FINDER: {
      let newArticles;
      let newKey;
      if (action.initial) {
        newArticles = sortByKey(Object.values(state.articles), action.key, null, action.desc);
        newKey = action.desc ? null : action.key;
      } else {
        newArticles = sortByKey(Object.values(state.articles), action.key, state.sort.sortKey);
        newKey = newArticles.newKey;
      }
      const newArticlesObject = {};
      newArticles.newModels.forEach((article) => {
        newArticlesObject[article.title] = article;
      });

      return {
        ...state,
        articles: newArticlesObject,
        sort: {
          sortKey: newKey,
          key: action.key,
        },
      };
    }
    case CLEAR_FINDER_STATE: {
      return { ...initialState, searchId: state.searchId + 1 };
    }
    case INITIATE_SEARCH: {
      return {
        ...state,
        articles: {},
        loading: true,
        continue_results: false,
        offset: 0,
        cmcontinue: '',
        sort: {
          sortKey: null,
          key: null
        },
        fetchState: 'ARTICLES_LOADING',
        lastRelevanceIndex: 0,
        searchId: state.searchId + 1,
        searchFailed: false,
      };
    }
    case END_SEARCH: {
      // No more data is coming. Articles still short of the final state are
      // ones whose data never arrived; moving them on lets their rows report
      // the missing value instead of showing a placeholder indefinitely.
      const newStateArticles = {};
      forEach(state.articles, (article, title) => {
        newStateArticles[title] = article.fetchState === 'PAGEVIEWS_RECEIVED'
          ? article
          : { ...article, fetchState: 'PAGEVIEWS_RECEIVED' };
      });

      return {
        ...state,
        articles: newStateArticles,
        loading: false,
        fetchState: 'PAGEVIEWS_RECEIVED',
        searchFailed: Boolean(action.failed) && isEmpty(state.articles),
      };
    }
    case RECEIVE_CATEGORY_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.query.categorymembers.forEach((data, i) => {
        newStateArticles[data.title] = {
          pageid: data.pageid,
          ns: data.ns,
          fetchState: 'TITLE_RECEIVED',
          title: data.title,
          relevanceIndex: i + state.lastRelevanceIndex + 1,
        };
      });
      let continueResults = false;
      let cmcontinue = '';
      if (action.data.continue) {
        continueResults = true;
        cmcontinue = action.data.continue.cmcontinue;
      }
      let fetchState = 'TITLE_RECEIVED';
      if (!action.data.query.categorymembers.length) {
        fetchState = 'PAGEVIEWS_RECEIVED';
      }
      return {
        ...state,
        articles: newStateArticles,
        continue_results: continueResults,
        cmcontinue,
        loading: false,
        fetchState,
        lastRelevanceIndex: state.lastRelevanceIndex + 50,
      };
    }
    case RECEIVE_KEYWORD_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.query.search.forEach((article, i) => {
        newStateArticles[article.title] = {
          pageid: article.pageid,
          ns: article.ns,
          fetchState: 'TITLE_RECEIVED',
          title: article.title,
          relevanceIndex: i + state.lastRelevanceIndex + 1,
        };
      });
      let continueResults = false;
      let offset = 0;
      if (action.data.continue) {
        continueResults = true;
        offset = action.data.continue.sroffset;
      }
      let fetchState = 'TITLE_RECEIVED';
      if (!action.data.query.search.length) {
        fetchState = 'PAGEVIEWS_RECEIVED';
      }
      return {
        ...state,
        articles: newStateArticles,
        continue_results: continueResults,
        offset,
        loading: false,
        fetchState,
        lastRelevanceIndex: state.lastRelevanceIndex + 50,
      };
    }
    case RECEIVE_ARTICLE_PAGEVIEWS: {
      const newStateArticles = cloneDeep(state.articles);
      forEach(action.data, (page) => {
        // MediaWiki may have normalized the title into another form than the
        // one that was asked about, in which case there is nothing to update.
        const article = newStateArticles[page.title];
        if (!article) { return; }

        // A page the API has no view data for comes back without the property.
        const dailyViews = Object.values(page.pageviews || {});
        const total = reduce(dailyViews, (result, value) => { return result + value; }, 0);
        article.pageviews = dailyViews.length ? Math.round((total / dailyViews.length) * 100) / 100 : 0;
        article.fetchState = 'PAGEVIEWS_RECEIVED';
      });

      return {
        ...state,
        articles: newStateArticles,
        fetchState: 'PAGEVIEWS_RECEIVED',
      };
    }
    case RECEIVE_ARTICLE_PAGEASSESSMENT: {
      const newStateArticles = cloneDeep(state.articles);
      forEach(action.data, (page) => {
        const article = newStateArticles[page.title];
        if (!article) { return; }

        article.grade = extractClassGrade(page.pageassessments);
        article.fetchState = 'PAGEASSESSMENT_RECEIVED';
      });

      return {
        ...state,
        articles: newStateArticles,
        fetchState: 'PAGEASSESSMENT_RECEIVED',
      };
    }
    case RECEIVE_ARTICLE_REVISION: {
      const newStateArticles = cloneDeep(state.articles);
      forEach(action.data, (page) => {
        const article = newStateArticles[page.title];
        // A page deleted since the search comes back with no revisions at all.
        if (!article || !page.revisions?.length) { return; }

        article.revid = page.revisions[0].revid;
        article.fetchState = 'REVISION_RECEIVED';
      });
      return {
        ...state,
        articles: newStateArticles,
        fetchState: 'REVISION_RECEIVED',
      };
    }
    case RECEIVE_ARTICLE_REVISIONSCORE: {
      const newStateArticles = cloneDeep(state.articles);
      forEach(action.data.data, (scores, revid) => {
        const article = find(newStateArticles, { revid: parseInt(revid) });
        if (!article) { return; }

        const revScore = reduce(LiftwingWeights[`${action.data.project === 'wikidata' ? 'wikidata' : action.data.language}`], (result, value, key) => {
          return result + (value * scores[`${action.data.project === 'wikidata' ? 'itemquality' : 'articlequality'}`].score.probability[key]);
        }, 0);
        article.revScore = Math.round(revScore * 100) / 100;
        article.fetchState = 'REVISIONSCORE_RECEIVED';
      });
      return {
        ...state,
        articles: newStateArticles,
        fetchState: 'REVISIONSCORE_RECEIVED',
      };
    }
    case CLEAR_RESULTS: {
      return {
        ...state,
        articles: {},
        loading: false,
        fetchState: 'PAGEVIEWS_RECEIVED',
        sort: {
          sortKey: null,
          key: null,
        },
        continue_results: false,
        offset: 0,
        cmcontinue: '',
        lastRelevanceIndex: 0,
        searchId: state.searchId + 1,
        searchFailed: false,
      };
    }
    default:
      return state;
  }
}
