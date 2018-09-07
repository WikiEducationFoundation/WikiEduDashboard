import _ from 'lodash';
import { sortByKey } from '../utils/model_utils';
import { RECEIVE_ARTICLES, SORT_ARTICLES, SET_PROJECT_FILTER } from '../constants';

const initialState = {
  articles: [],
  limit: 500,
  limitReached: false,
  sort: {
    key: null,
    sortKey: null,
  },
  wikis: [],
  wikiFilter: null,
  loading: true
};

const SORT_DESCENDING = {
  character_sum: true,
  view_count: true
};

const isLimitReached = (revs, limit) => {
  return (revs.length < limit);
};

const mapWikis = (article) => {
  return {
    language: article.language,
    project: article.project
  };
};

export default function articles(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLES: {
      const wikis = _.uniqWith(_.map(action.data.course.articles, mapWikis), _.isEqual);
      return {
        ...state,
        articles: action.data.course.articles,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.articles, action.limit),
        wikis: wikis,
        wikiFilter: state.wikiFilter,
        loading: false
      };
    }
    case SORT_ARTICLES: {
      const newState = { ...state };
      const sorted = sortByKey(newState.articles, action.key, state.sort.sortKey, SORT_DESCENDING[action.key]);
      newState.articles = sorted.newModels;
      newState.sort.sortKey = sorted.newKey;
      newState.sort.key = action.key;
      newState.wikiFilter = state.wikiFilter;
      newState.wikis = state.wikis;
      return newState;
    }
    case SET_PROJECT_FILTER: {
      if (action.wiki.project === 'all') {
        return { ...state, wikiFilter: null };
      }
      return { ...state, wikiFilter: action.wiki };
    }
    default:
      return state;
  }
}
