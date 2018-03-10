import _ from 'lodash';
import { sortByKey } from '../utils/model_utils';
import { RECEIVE_ARTICLES, SORT_ARTICLES, SET_PROJECT_FILTER } from '../constants';

const initialState = {
  articles: [],
  limit: 500,
  limitReached: false,
  sortKey: null,
  projects: [],
  projectFilter: null,
};

const SORT_DESCENDING = {
  character_sum: true,
  view_count: true
};


const isLimitReached = (revs, limit) => {
  return (revs.length < limit);
};

export default function articles(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ARTICLES: {
      const projects = _.uniq(_.map(action.data.course.articles, 'project'));
      return {
        articles: action.data.course.articles,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.articles, action.limit),
        projects: projects,
        projectFilter: state.projectFilter
      };
    }
    case SORT_ARTICLES: {
      const newState = { ...state };
      const sorted = sortByKey(newState.articles, action.key, state.sortKey, SORT_DESCENDING[action.key]);
      newState.articles = sorted.newModels;
      newState.sortKey = sorted.newKey;
      newState.projectFilter = state.projectFilter;
      newState.projects = state.projects;
      return newState;
    }
    case SET_PROJECT_FILTER: {
      if (action.project === "all") {
        return { ...state, projectFilter: null };
      }
      return { ...state, projectFilter: action.project };
    }
    default:
      return state;
  }
}
