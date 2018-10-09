import { RECEIVE_RECENT_EDITS, SORT_RECENT_EDITS } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  revisions: [],
  sortKey: null,
  loading: true
};


export default function recentEdits(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_RECENT_EDITS: {
      return {
        revisions: action.payload.data.revisions,
        sortKey: state.sortKey,
        loading: false
      };
    }
    case SORT_RECENT_EDITS: {
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
