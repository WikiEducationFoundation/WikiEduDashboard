import { RECEIVE_SUSPECTED_PLAGIARISM, SORT_SUSPECTED_PLAGIARISM } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  revisions: [],
  sort: {
    key: null,
    sortKey: null,
  },
  loading: true
};

export default function suspectedPlagiarism(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_SUSPECTED_PLAGIARISM: {
      return {
        revisions: action.payload.data.revisions,
        sort: state.sort,
        loading: false
      };
    }
    case SORT_SUSPECTED_PLAGIARISM: {
      const desc = action.key === state.sort.sortKey;
      const newRevisions = sortByKey(state.revisions, action.key, null, desc);
      return {
        revisions: newRevisions.newModels,
        sort: {
          sortKey: desc ? null : action.key,
          key: action.key
        },
        loading: state.loading
      };
    }
    default:
      return state;
  }
}
