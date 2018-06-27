import _ from 'lodash';
import { extractClassGrade } from '../utils/article_finder_utils.js';
import { sortByKey } from '../utils/model_utils';
import { WP10Weights } from '../utils/article_finder_language_mappings.js';
import { UPDATE_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE,
  RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT,
  RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, RECEIVE_KEYWORD_RESULTS } from "../constants";

const initialState = {
  articles: {},
  search_type: "keyword",
  search_term: "",
  depth: "",
  min_views: "0",
  article_quality: 100,
  loading: false,
  fetchState: "PAGEVIEWS_RECEIVED",
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
    case UPDATE_FIELD: {
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
      }
      else {
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
      return {
        ...state,
        articles: {},
        loading: true,
        continue_results: false,
        offset: 0,
        totalhits: 0,
        sort: {
          sortKey: null,
          key: null
        },
        fetchState: "ARTICLES_LOADING",
      };
    }
    case RECEIVE_CATEGORY_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.query.categorymembers.forEach((data, i) => {
        newStateArticles[data.title] = {
          pageid: data.pageid,
          ns: data.ns,
          fetchState: "TITLE_RECEIVED",
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
      return {
        ...state,
        articles: newStateArticles,
        continue_results: continueResults,
        cmcontinue: cmcontinue,
        loading: false,
        fetchState: "TITLE_RECEIVED",
        lastRelevanceIndex: state.lastRelevanceIndex + 50,
      };
    }
    case RECEIVE_KEYWORD_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.query.search.forEach((article, i) => {
        newStateArticles[article.title] = {
          pageid: article.pageid,
          ns: article.ns,
          fetchState: "TITLE_RECEIVED",
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
      return {
        ...state,
        articles: newStateArticles,
        continue_results: continueResults,
        offset: offset,
        loading: false,
        fetchState: "TITLE_RECEIVED",
        lastRelevanceIndex: state.lastRelevanceIndex + 50,
      };
    }
    case RECEIVE_ARTICLE_PAGEVIEWS: {
      const newStateArticles = _.cloneDeep(state.articles);
      _.forEach(action.data, (article) => {
        const averagePageviews = Math.round((_.reduce(article.pageviews, (result, value) => { return result + value; }, 0) / Object.values(article.pageviews).length) * 100) / 100;
        newStateArticles[article.title].pageviews = averagePageviews;
        newStateArticles[article.title].fetchState = "PAGEVIEWS_RECEIVED";
      });

      return {
        ...state,
        articles: newStateArticles,
        fetchState: "PAGEVIEWS_RECEIVED",
      };
    }
    case RECEIVE_ARTICLE_PAGEASSESSMENT: {
      const newStateArticles = _.cloneDeep(state.articles);
      _.forEach(action.data, (article) => {
        const grade = extractClassGrade(article.pageassessments);

        newStateArticles[article.title].grade = grade;
        newStateArticles[article.title].fetchState = "PAGEASSESSMENT_RECEIVED";
      });

      return {
        ...state,
        articles: newStateArticles,
        fetchState: "PAGEASSESSMENT_RECEIVED",
      };
    }
    case RECEIVE_ARTICLE_REVISION: {
      const newStateArticles = _.cloneDeep(state.articles);
      _.forEach(action.data, (value) => {
        newStateArticles[value.title].revid = value.revisions[0].revid;
        newStateArticles[value.title].fetchState = "REVISION_RECEIVED";
      });
      return {
        ...state,
        articles: newStateArticles,
        fetchState: "REVISION_RECEIVED",
      };
    }
    case RECEIVE_ARTICLE_REVISIONSCORE: {
      const newStateArticles = _.cloneDeep(state.articles);
      _.forEach(action.data.data, (scores, revid) => {
        const revScore = _.reduce(WP10Weights[action.data.language], (result, value, key) => {
          return result + value * scores.wp10.score.probability[key];
        }, 0);
        const article = _.find(newStateArticles, { revid: parseInt(revid) });
        article.revScore = Math.round(revScore * 100) / 100;
        article.fetchState = "REVISIONSCORE_RECEIVED";
      });
      return {
        ...state,
        articles: newStateArticles,
        fetchState: "REVISIONSCORE_RECEIVED",
      };
    }
    default:
      return state;
  }
}
