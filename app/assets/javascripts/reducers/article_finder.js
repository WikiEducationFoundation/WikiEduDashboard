import _ from 'lodash';
import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE } from "../constants";

const initialState = {
  articles: {},
  loading: false
};

export default function articleFinder(state = initialState, action) {
  switch (action.type) {
    case CLEAR_FINDER_STATE: {
      return {
        articles: {},
        loading: false
      };
    }
    case RECEIVE_CATEGORY_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.forEach((data) => {
        newStateArticles[data.title] = {
          pageid: data.pageid,
          ns: data.ns,
        };
      });
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_PAGEVIEWS: {
      const newStateArticles = _.cloneDeep(state.articles);
      const title = action.data.title.replace(/_/g, ' ');
      newStateArticles[title].pageviews = action.data.pageviews;
      // const article = _.find(newStateArticles, { title: title });
      // article.pageviews = action.data.pageviews;
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_PAGEASSESSMENT: {
      const newStateArticles = _.cloneDeep(state.articles);
      newStateArticles[action.data.title].grade = action.data.classGrade;
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_REVISION: {
      const newStateArticles = _.cloneDeep(state.articles);
      action.data.forEach((data) => {
        // const article = _.find(newStateArticles, { title: data.title });
        newStateArticles[data.title].revid = data.revid;
      });
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_REVISIONSCORE: {
      const newStateArticles = _.cloneDeep(state.articles);
      action.data.forEach((data) => {
        const article = _.find(newStateArticles, { revid: parseInt(data.revid) });
        article.revScore = data.revScore;
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
