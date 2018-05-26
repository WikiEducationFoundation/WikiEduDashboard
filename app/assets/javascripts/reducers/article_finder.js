import _ from 'lodash';
import { extractClassGrade } from '../utils/article_finder_utils.js';

import { UPDATE_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE,
  RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT,
  RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, WP10Weights } from "../constants";

const initialState = {
  articles: {},
  category: "",
  depth: "",
  min_views: "0",
  max_completeness: "100",
  grade: "FA",
  loading: false
};

export default function articleFinder(state = initialState, action) {
  switch (action.type) {
    case UPDATE_FIELD: {
      const newState = { ...state };
      newState[action.data.key] = action.data.value;
      return newState;
    }
    case CLEAR_FINDER_STATE: {
      return {
        ...state,
        articles: {},
        loading: true,
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
