import _ from 'lodash';
import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS,
 RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION,
 RECEIVE_ARTICLE_REVISIONSCORE, TITLE_RECEIVED, PAGEASSESSMENT_RECEIVED,
 REVISION_RECEIVED, REVISIONSCORE_RECEIVED, PAGEVIEWS_RECEICED } from "../constants";

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
          fetchState: TITLE_RECEIVED
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
      newStateArticles[title].fetchState = PAGEVIEWS_RECEICED;
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    case RECEIVE_ARTICLE_PAGEASSESSMENT: {
      const newStateArticles = _.cloneDeep(state.articles);
      action.data.forEach((data) => {
        newStateArticles[data.title].grade = data.classGrade;
        newStateArticles[data.title].fetchState = PAGEASSESSMENT_RECEIVED;
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
        newStateArticles[data.title].fetchState = REVISION_RECEIVED;
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
        article.fetchState = REVISIONSCORE_RECEIVED;
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
