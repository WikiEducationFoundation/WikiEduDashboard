import { sortByKey } from '../utils/model_utils';
import { RECEIVE_COURSE_SEARCH_RESULTS, SORT_COURSE_SEARCH_RESULTS, FETCH_COURSE_SEARCH_RESULTS } from '../constants/course_search_results';
import { COURSE_SORT_DESCENDING } from '../utils/course_utils';

const initialState = {
  results: [],
  loaded: false,
  sort: {
    key: null,
    sortKey: null,
  },
};

export default function search_results(state = initialState, action) {
  switch (action.type) {
    case FETCH_COURSE_SEARCH_RESULTS: {
      return {
        ...state,
        loaded: false
      };
    }
    case RECEIVE_COURSE_SEARCH_RESULTS: {
      const newState = {
        ...state,
        results: action.data.courses,
        loaded: true
      };
      return newState;
    }
    case SORT_COURSE_SEARCH_RESULTS: {
      const sorted = sortByKey(
        state.results,
        action.key,
        state.sort.sortKey,
        COURSE_SORT_DESCENDING[action.key]
      );
      return {
        ...state,
        results: sorted.newModels,
        sort: {
          sortKey: sorted.newKey,
          key: action.key
        },
      };
    }
    default:
      return state;
  }
}
