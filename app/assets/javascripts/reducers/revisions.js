import { RECEIVE_REVISIONS, SORT_REVISIONS } from '../constants';
import _ from 'lodash';

const initialState = {
  revisions: [],
  limit: 50,
  limitReached: false,
  sortKey: null
};

const isLimitReached = (revs, limit) => {
  return (revs.length < limit);
};

export default function revisions(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_REVISIONS:
      return {
        revisions: action.data.course.revisions,
        limit: action.limit,
        limitReached: isLimitReached(action.data.course.revisions, action.limit)
      };
    case SORT_REVISIONS: {
      const newState = { ...state };
      if (action.key === state.sortKey) {
        newState.revisions = _.sortBy(state.revisions, action.key).reverse();
        newState.sortKey = null;
      } else {
        newState.revisions = _.sortBy(state.revisions, action.key);
        newState.sortKey = action.key;
      }
      return newState;
    }
    default:
      return state;
  }
}
