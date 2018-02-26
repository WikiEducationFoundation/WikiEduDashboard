import { RECEIVE_RECENT_UPLOADS, SORT_RECENT_UPLOADS } from "../constants";
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
  loading: true
};

export default function recentUploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_RECENT_UPLOADS: {
      return {
        uploads: action.payload.data.uploads,
        sortKey: state.sortKey,
        loading: false
      };
    }
    case SORT_RECENT_UPLOADS: {
      const newUploads = sortByKey(state.uploads, action.key, state.sortKey);
      return {
        uploads: newUploads.newModels,
        sortKey: newUploads.newKey,
        loading: state.loading
      };
    }
    default:
      return state;
  }
}
