import _ from 'lodash';
import { RECEIVE_REVISIONS, SORT_REVISIONS } from '../constants';

const initialState = {
  revisions: [],
  limit: 50,
  limitReached: false,
  sort: {
    key: null,
    sortKey: null,
  },
  loading: true
};

const isLimitReached = (revs, limit) => {
  return (revs.length < limit);
};

export default function revisions(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_REVISIONS:
      return {
        ...state,
        revisions: action.data.course.revisions,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.revisions, action.limit),
        loading: false
      };
    case SORT_REVISIONS: {
      const newState = { ...state };
      if (action.key === state.sort.sortKey) {
        newState.revisions = _.sortBy(state.revisions, action.key).reverse();
        newState.sort.sortKey = null;
      } else {
        newState.revisions = _.sortBy(state.revisions, action.key);
        newState.sort.sortKey = action.key;
      }
      newState.sort.key = action.key;
      return newState;
    }
    default:
      return state;
  }
}
