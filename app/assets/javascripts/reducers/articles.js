import { uniqWith, map, isEqual } from 'lodash-es';
import { sortByKey } from '../utils/model_utils';
import {
  RECEIVE_ARTICLES,
  SORT_ARTICLES,
  SET_PROJECT_FILTER,
  SET_NEWNESS_FILTER,
  SET_TRACKED_STATUS_FILTER,
  UPDATE_ARTICLE_TRACKED_STATUS
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
  wikiFilter: { project: 'all' },
  newnessFilter: 'both',
  trackedStatusFilter: 'tracked',
  loading: true,
  newnessFilterEnabled: false,
  trackedStatusFilterEnabled: false
};

const SORT_DESCENDING = {
  character_sum: true,
  references_count: true,
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

const getTrackedStatusFilterEnabledStatus = _articles =>
  _articles.some(a => a.tracked) && _articles.some(a => !a.tracked);

const getDefaultTrackedStatusFilter = _articles =>
  ((_articles[0] && _articles[0].tracked) ? 'tracked' : 'both');

export default function articles(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLES: {
      const wikis = uniqWith(
        map(action.data.course.articles, mapWikis),
        isEqual
      );
      const _articles = action.data.course.articles;
      const newnessFilterEnabled = _articles.some(a => a.new_article) && _articles.some(a => !a.new_article);
      const trackedStatusFilterEnabled = getTrackedStatusFilterEnabledStatus(_articles);
      let trackedStatusFilter = state.trackedStatusFilter;
      if (!trackedStatusFilterEnabled) {
        trackedStatusFilter = getDefaultTrackedStatusFilter(_articles);
      }
      return {
        ...state,
        articles: _articles,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.articles, action.limit),
        wikis,
        wikiFilter: state.wikiFilter,
        newnessFilter: state.newnessFilter,
        trackedStatusFilter,
        newnessFilterEnabled,
        trackedStatusFilterEnabled,
        loading: false
      };
    }

    case SORT_ARTICLES: {
      const sorted = sortByKey(
        state.articles,
        action.key,
        state.sort.sortKey,
        SORT_DESCENDING[action.key],
        undefined,
        action.refresh
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
        return { ...state, wikiFilter: { project: 'all' } };
      }
      return { ...state, wikiFilter: action.wiki };
    }

    case SET_NEWNESS_FILTER: {
      return { ...state, newnessFilter: action.newness };
    }

    case SET_TRACKED_STATUS_FILTER: {
      return { ...state, trackedStatusFilter: action.trackedStatus };
    }

    case UPDATE_ARTICLE_TRACKED_STATUS: {
      // Make sure the article's tracked status is reflected in the redux state
      const updatedArticles = state.articles.map((a) => {
        if (a.id === action.articleId) {
          a.tracked = action.tracked;
        }
        return a;
      });
      let { trackedStatusFilter } = state;
      const trackedStatusFilterEnabled = getTrackedStatusFilterEnabledStatus(updatedArticles);
      if (!trackedStatusFilterEnabled) {
        trackedStatusFilter = getDefaultTrackedStatusFilter(updatedArticles);
      } else if (trackedStatusFilter === 'tracked') {
        trackedStatusFilter = 'both';
      }
      return { ...state, trackedStatusFilterEnabled, trackedStatusFilter, articles: updatedArticles };
    }

    default:
      return state;
  }
}
