import { RECEIVE_DYK, SORT_DYK } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  articles: [],
  sortKey: null,
  loading: true
};

export default function didYouKnow(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_DYK: {
      return {
        articles: action.payload.data.articles,
        sortKey: state.sortKey,
        loading: false
      };
    }
    case SORT_DYK: {
      const newArticles = sortByKey(state.articles, action.key, state.sortKey);
      return {
        articles: newArticles.newModels,
        sortKey: newArticles.newKey,
        loading: state.loading
      };
    }
    default:
      return state;
  }
}
