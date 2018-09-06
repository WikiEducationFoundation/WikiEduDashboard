import { RECEIVE_RECENT_UPLOADS, SORT_RECENT_UPLOADS } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
  loading: true
};

const SORT_DESCENDING = {
  uploaded_at: true,
  usage_count: true,
};

export default function recentUploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_RECENT_UPLOADS: {
      const dataUploads = action.data.uploads;
      // Initial sorting by upload date
      const sortedModel = sortByKey(dataUploads, 'uploaded_at', state.sortKey, SORT_DESCENDING.uploaded_at);
      return {
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
      };
    }
    case SORT_RECENT_UPLOADS: {
      const sortedModel = sortByKey(state.uploads, action.key, state.sortKey, SORT_DESCENDING[action.key]);
      return {
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
      };
    }
    default:
      return state;
  }
}
