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
        loading: true,
      };
    }
    case RECEIVE_CATEGORY_RESULTS: {
      const newStateArticles = { ...state.articles };
      action.data.forEach((data) => {
        newStateArticles[data.title] = {
          pageid: data.pageid,
          ns: data.ns,
          fetchState: 1
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
      newStateArticles[title].fetchState = 5;
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_PAGEASSESSMENT: {
      const newStateArticles = _.cloneDeep(state.articles);
      action.data.forEach((data) => {
        newStateArticles[data.title].grade = data.classGrade;
        newStateArticles[data.title].fetchState = 2;
      });
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_REVISION: {
      const newStateArticles = _.cloneDeep(state.articles);
      action.data.forEach((data) => {
        newStateArticles[data.title].revid = data.revid;
        newStateArticles[data.title].fetchState = 3;
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
        article.fetchState = 4;
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
