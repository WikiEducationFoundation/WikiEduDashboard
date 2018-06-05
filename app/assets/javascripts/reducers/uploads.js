import { RECEIVE_UPLOADS, SORT_UPLOADS } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
  count: null,
};

const SORT_DESCENDING = {
  uploaded_at: true,
  usage_count: true,
};

export default function uploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_UPLOADS: {
      const dataUploads = action.data.course.uploads;
      return {
        uploads: dataUploads,
        sortKey: null,
        count: action.data.course.count,
      };
    }
    case SORT_UPLOADS: {
      const sortedModel = sortByKey(state.uploads, action.key, state.sortKey, SORT_DESCENDING[action.key]);
      return {
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
        count: state.count,
      };
    }
    default:
      return state;
  }
}
