import _ from 'lodash';
import { extractClassGrade } from '../utils/article_finder_utils.js';
import { sortByKey } from '../utils/model_utils';

import { UPDATE_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE,
  RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT,
  RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, WP10Weights, RECEIVE_KEYWORD_RESULTS } from "../constants";

const initialState = {
  articles: {},
  search_type: "category",
  search_term: "",
  depth: "",
  min_views: "0",
  article_quality: 100,
  loading: false,
  sortKey: null,
  continue_results: false,
  offset: 0,
  totalhits: 0,
};

export default function articleFinder(state = initialState, action) {
  switch (action.type) {
    case UPDATE_FIELD: {
      const newState = { ...state };
      newState[action.data.key] = action.data.value;
      return newState;
    }
    case SORT_ARTICLE_FINDER: {
      const newArticles = sortByKey(Object.values(state.articles), action.key, state.sortKey);
      const newArticlesObject = {};
      newArticles.newModels.forEach((article) => {
        newArticlesObject[article.title] = article;
      });

      return {
        ...state,
        articles: newArticlesObject,
        sortKey: newArticles.newKey,
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
      };
    }
    case RECEIVE_CATEGORY_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.forEach((data) => {
        newStateArticles[data.title] = {
          pageid: data.pageid,
          ns: data.ns,
          fetchState: "TITLE_RECEIVED",
          title: data.title,
        };
      });
      return {
        ...state,
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_KEYWORD_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.query.search.forEach((article) => {
        newStateArticles[article.title] = {
          pageid: article.pageid,
          ns: article.ns,
          fetchState: "TITLE_RECEIVED",
          title: article.title,
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
        totalhits: action.data.query.searchinfo.totalhits,
        continue_results: continueResults,
        offset: offset,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_PAGEVIEWS: {
      const newStateArticles = _.cloneDeep(state.articles);
      const title = action.data[0].article.replace(/_/g, ' ');
      const averagePageviews = Math.round((_.sumBy(action.data, (o) => { return o.views; }) / action.data.length) * 100) / 100;

      newStateArticles[title].pageviews = averagePageviews;
      newStateArticles[title].fetchState = "PAGEVIEWS_RECEIVED";

      return {
        ...state,
        articles: newStateArticles,
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
      };
    }
    case RECEIVE_ARTICLE_REVISIONSCORE: {
      const newStateArticles = _.cloneDeep(state.articles);
      _.forEach(action.data, (scores, revid) => {
        const revScore = _.reduce(WP10Weights, (result, value, key) => {
          return result + value * scores.wp10.score.probability[key];
        }, 0);
        const article = _.find(newStateArticles, { revid: parseInt(revid) });
        article.revScore = Math.round(revScore * 100) / 100;
        article.fetchState = "REVISIONSCORE_RECEIVED";
      });
      return {
        ...state,
        articles: newStateArticles,
      };
    }
    default:
      return state;
  }
}
