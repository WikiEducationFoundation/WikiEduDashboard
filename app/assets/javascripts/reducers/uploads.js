import { RECEIVE_UPLOADS, SORT_UPLOADS } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
};

const SORT_DESCENDING = {
  usage_count: true,
  date: true,
  uploader: true
};

export default function uploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_UPLOADS: {
      const dataUploads = action.data.course.uploads;
      //Intial sorting by file name
      const sortedModel = sortByKey(dataUploads, 'file_name', state.sortKey, SORT_DESCENDING[action.key]);
      return {
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
      };
    }
    case SORT_UPLOADS: {
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
