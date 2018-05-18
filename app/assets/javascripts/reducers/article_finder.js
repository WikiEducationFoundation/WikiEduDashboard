import _ from 'lodash';
import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE } from "../constants";

const initialState = {
  articles: [],
  loading: false
};

export default function articleFinder(state = initialState, action) {
  switch (action.type) {
    case CLEAR_FINDER_STATE: {
      return {
        articles: [],
        loading: false
      };
    }
    case RECEIVE_CATEGORY_RESULTS: {
      let newStateArticles = state.articles.map(article => ({ ...article }));
      newStateArticles = _.concat(newStateArticles, action.data);
      return {
        articles: newStateArticles,
        loading: false
      };
    }
    default:
      return state;
  }
}
