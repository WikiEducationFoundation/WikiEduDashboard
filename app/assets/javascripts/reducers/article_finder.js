import _ from 'lodash';
import { extractClassGrade } from '../utils/article_finder_utils.js';

import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS,
 RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION,
 RECEIVE_ARTICLE_REVISIONSCORE } from "../constants";

const initialState = {
  articles: {},
  loading: false
};

export default function articleFinder(state = initialState, action) {
  switch (action.type) {
    case CLEAR_FINDER_STATE: {
      return {
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
          fetchState: "TITLE_RECEIVED"
        };
      });
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_PAGEVIEWS: {
      const newStateArticles = _.cloneDeep(state.articles);
      const title = action.data[0].article.replace(/_/g, ' ');
      const averagePageviews = Math.round((_.sumBy(action.data, (o) => { return o.views; }) / action.data.length) * 100) / 100;

      newStateArticles[title].pageviews = averagePageviews;
      newStateArticles[title].fetchState = "PAGEVIEWS_RECEICED";
      return {
        articles: newStateArticles,
        loading: false
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
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_REVISION: {
      const newStateArticles = _.cloneDeep(state.articles);
      _.forEach(action.data, (value) => {
        newStateArticles[value.title].revid = value.revisions[0].revid;
        newStateArticles[value.title].fetchState = "REVISION_RECEIVED";
      });
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_REVISIONSCORE: {
      const newStateArticles = _.cloneDeep(state.articles);
      const WP10Weights = { FA: 100, GA: 80, B: 60, C: 40, Start: 20, Stub: 0 };
      _.forEach(action.data, (scores, revid) => {
        const revScore = _.reduce(WP10Weights, (result, value, key) => {
          return result + value * scores.wp10.score.probability[key];
        }, 0);
        const article = _.find(newStateArticles, { revid: parseInt(revid) });
        article.revScore = Math.round(revScore * 100) / 100;
        article.fetchState = "REVISIONSCORE_RECEIVED";
      });
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    default:
      return state;
  }
}
