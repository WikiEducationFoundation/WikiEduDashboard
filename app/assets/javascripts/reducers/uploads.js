import _ from 'lodash';
import {
  RECEIVE_UPLOADS,
  SORT_UPLOADS,
  SET_VIEW,
  GALLERY_VIEW,
  FILTER_UPLOADS,
  SET_UPLOAD_METADATA,
  SET_UPLOAD_VIEWER_METADATA,
  SET_UPLOAD_PAGEVIEWS
} from '../constants';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  uploads: [],
  sortKey: null,
  view: GALLERY_VIEW,
  selectedFilters: [],
  loading: true,
  uploadMetadata: {}
};

const SORT_DESCENDING = {
  uploaded_at: true,
  usage_count: true,
};

export default function uploads(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_UPLOADS: {
      const dataUploads = action.data.course.uploads;
      // Intial sorting by upload date
      const sortedModel = sortByKey(dataUploads, 'uploaded_at', state.sortKey, SORT_DESCENDING.uploaded_at);

      return {
        ...state,
        uploads: sortedModel.newModels,
        sortKey: sortedModel.newKey,
        loading: false
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
      let fetchedData;
      _.forEach(action.data, data => {
        if (data.query) {
          fetchedData = { ...fetchedData, ...data.query.pages };
        }
      });
      const updatedUploads = state.uploads.map(upload => {
        if (fetchedData && fetchedData[upload.id]) {
          upload.credit = _.get(fetchedData, `${upload.id}.imageinfo[0].extmetadata.Credit.value`, 'Not found');
          if (!upload.thumburl) {
            upload.thumburl = _.get(fetchedData, `${upload.id}.imageinfo[0].thumburl`);
          }
          upload.fetchState = true;
        }
        return upload;
      });
      return {
        ...state,
        uploads: updatedUploads,
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
    case SET_UPLOAD_VIEWER_METADATA: {
      return {
        ...state,
        uploadMetadata: action.data,
      };
    }
    case SET_UPLOAD_PAGEVIEWS: {
      const averageViews = [];
      _.forEach(action.data, fileView => {
        let fileViews = 0;
        _.forEach(fileView.items, article => {
          fileViews += _.get(article, 'views');
        });
        averageViews.push(Math.round((fileViews / 60) * 10) / 10);
      });
      return {
        ...state,
        averageViews: averageViews,
      };
    }
    default:
      return state;
  }
}
