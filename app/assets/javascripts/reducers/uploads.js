import _ from 'lodash';
import { RECEIVE_UPLOADS, SORT_UPLOADS, SET_VIEW, GALLERY_VIEW, FILTER_UPLOADS, SET_UPLOAD_METADATA } from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
  view: GALLERY_VIEW,
  selectedFilters: [],
  updatedUploads: {},
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
    case SET_UPLOAD_METADATA: {
      let updatedUploads;
      _.forEach(action.data, data => {
        if (data.query) {
          updatedUploads = { ...updatedUploads, ...data.query.pages };
        }
      });
      return {
        ...state,
        updatedUploads: updatedUploads,
      };
    }
    case SET_VIEW: {
      return {
        ...state,
        view: action.view,
      };
    }
    case FILTER_UPLOADS: {
      return {
        ...state,
        selectedFilters: action.selectedFilters,
      };
    }
    default:
      return state;
  }
}
