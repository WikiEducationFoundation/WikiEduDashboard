import { RECEIVE_SUSPECTED_PLAGIARISM, SORT_SUSPECTED_PLAGIARISM } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  revisions: [],
  sortKey: null,
  loading: true
};

export default function suspectedPlagiarism(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_SUSPECTED_PLAGIARISM: {
      return {
        revisions: action.payload.data.revisions,
        sortKey: state.sortKey,
        loading: false
      };
    }
    case SORT_SUSPECTED_PLAGIARISM: {
      const newRevisions = sortByKey(state.revisions, action.key, state.sortKey);
      return {
        revisions: newRevisions.newModels,
        sortKey: newRevisions.newKey,
        loading: state.loading
      };
    }
    default:
      return state;
  }
}
