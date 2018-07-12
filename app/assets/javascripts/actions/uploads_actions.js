import _ from 'lodash';
import { RECEIVE_UPLOADS, SORT_UPLOADS, SET_VIEW, FILTER_UPLOADS, SET_UPLOAD_METADATA, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchUploads = (courseId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/uploads.json`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const receiveUploads = (courseId) => dispatch => {
  return (
    fetchUploads(courseId)
      .then(resp => dispatch({
        type: RECEIVE_UPLOADS,
        data: resp,
      }))
      .catch(resp => dispatch({
        type: API_FAIL,
        data: resp
      }))
  );
};

const fetchUploadMetadata = (uploads) => {
  let url = `https://commons.wikimedia.org/w/api.php?action=query&format=json&titles=`;
  _.forEach(uploads, upload => {
    url = `${url}File:${encodeURIComponent(upload.file_name)}|`;
  });
  url = url.slice(0, -1);
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `${url}&prop=imageinfo&iiprop=extmetadata|url&iiextmetadatafilter=Credit&iiurlwidth=640px`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const setUploadMetadata = (uploadsList) => dispatch => {
  const list = uploadsList.filter(upload => !upload.fetchState);
  const promises = _.chunk(list, 25).map(uploads => fetchUploadMetadata(uploads));
  return (
    Promise.all(promises)
    .then(resp => dispatch({
      type: SET_UPLOAD_METADATA,
      data: resp,
    }))
    .catch(resp => dispatch({
      type: API_FAIL,
      data: resp
    }))
  );
};

export const sortUploads = key => ({ type: SORT_UPLOADS, key: key });

export const setView = view => ({ type: SET_VIEW, view: view });

export const setUploadFilters = selectedFilters => ({ type: FILTER_UPLOADS, selectedFilters: selectedFilters });
