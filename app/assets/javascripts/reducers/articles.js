import _ from 'lodash';
import { sortByKey } from '../utils/model_utils';
import {
  RECEIVE_ARTICLES,
  SORT_ARTICLES,
  SET_PROJECT_FILTER,
  SET_NEWNESS_FILTER
} from '../constants';

const initialState = {
  articles: [],
  limit: 500,
  limitReached: false,
  sort: {
    key: null,
    sortKey: null
  },
  wikis: [],
  wikiFilter: null,
  newnessFilter: null,
  loading: true,
  newnessFilterEnabled: false
};

const SORT_DESCENDING = {
  character_sum: true,
  view_count: true
};

const isLimitReached = (revs, limit) => {
  return revs.length < limit;
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
      const wikis = _.uniqWith(
        _.map(action.data.course.articles, mapWikis),
        _.isEqual
      );
      const _articles = action.data.course.articles;
      const newnessFilterEnabled = _articles.some(a => a.new_article) && _articles.some(a => !a.new_article);
      return {
        ...state,
        articles: _articles,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.articles, action.limit),
        wikis,
        wikiFilter: state.wikiFilter,
        newnessFilter: state.newnessFilter,
        newnessFilterEnabled,
        loading: false
      };
    }

    case SORT_ARTICLES: {
      const sorted = sortByKey(
        state.articles,
        action.key,
        state.sort.sortKey,
        SORT_DESCENDING[action.key]
      );
      return {
        ...state,
        articles: sorted.newModels,
        sort: {
          sortKey: sorted.newKey,
          key: action.key
        },
        wikiFilter: state.wikiFilter,
        wikis: state.wikis
      };
    }

    case SET_PROJECT_FILTER: {
      if (action.wiki.project === 'all') {
        return { ...state, wikiFilter: null };
      }
      return { ...state, wikiFilter: action.wiki };
    }

    case SET_NEWNESS_FILTER: {
      return { ...state, newnessFilter: action.newness };
    }

    default:
      return state;
  }
}
