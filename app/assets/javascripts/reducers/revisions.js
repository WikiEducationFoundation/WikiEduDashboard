import { RECEIVE_REVISIONS, SORT_REVISIONS } from '../constants';
import { sortByKey } from '../utils/model_utils';

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
      const absolute = action.key === 'characters';
      const desc = action.key === state.sort.sortKey;
      const sortedRevisions = sortByKey(state.revisions, action.key, null, desc, absolute);
      return { ...state,
        revisions: sortedRevisions.newModels,
        sort: {
          sortKey: desc ? null : action.key,
          key: action.key
        }
      };
    }
    default:
      return state;
  }
}
