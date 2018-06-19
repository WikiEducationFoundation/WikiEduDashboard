import { RECEIVE_UPLOADS, SORT_UPLOADS, SET_TABULAR_VIEW } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
  isTabularView: false,
};

const SORT_DESCENDING = {
  uploaded_at: true,
  usage_count: true,
};

export default function uploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_UPLOADS: {
      const dataUploads = action.data.course.uploads;
      //Intial sorting by upload date
      const sortedModel = sortByKey(dataUploads, 'uploaded_at', state.sortKey, SORT_DESCENDING.uploaded_at);
      return {
        ...state,
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
      };
    }
    case SORT_UPLOADS: {
      const sortedModel = sortByKey(state.uploads, action.key, state.sortKey, SORT_DESCENDING[action.key]);
      return {
        ...state,
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
      };
    }
    case SET_TABULAR_VIEW: {
      return {
        ...state,
        isTabularView: action.isTabularView,
      };
    }
    default:
      return state;
  }
}
