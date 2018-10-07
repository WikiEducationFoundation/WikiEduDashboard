import _ from 'lodash';
import { RECEIVE_UPLOADS, SORT_UPLOADS, SET_VIEW, FILTER_UPLOADS, SET_UPLOAD_METADATA, API_FAIL, SET_UPLOAD_VIEWER_METADATA, SET_UPLOAD_PAGEVIEWS } from '../constants';
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
  let url = 'https://commons.wikimedia.org/w/api.php?action=query&origin=*&format=json&pageids=';
  _.forEach(uploads, upload => {
    url = `${url}${upload.id}|`;
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
  if (list.length === 0) { return; }
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

const fetchUploadViewerMetadata = (upload) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: 'https://commons.wikimedia.org/w/api.php?',
      data: {
        action: 'query',
        origin: '*',
        format: 'json',
        pageids: upload.id,
        prop: 'globalusage|categories|imageinfo',
        iiprop: 'size|extmetadata|url',
        clshow: '!hidden',
      },
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

export const setUploadViewerMetadata = (upload) => dispatch => {
  return (
    fetchUploadViewerMetadata(upload)
      .then(resp => dispatch({
        type: SET_UPLOAD_VIEWER_METADATA,
        data: resp,
      }))
      .catch(resp => dispatch({
        type: API_FAIL,
        data: resp
      }))
  );
};

const fetchUploadPageViews = (articleList) => {
  const viewPerArticle = [];
  // set the start date to 60 days form today
  const rawDate = new Date();
  rawDate.setDate(rawDate.getDate() - 60);
  const startDate = new Date(rawDate).toJSON().slice(0, 10).replace(/-/g, '');
  const endDate = new Date().toJSON().slice(0, 10).replace(/-/g, '');
  articleList.map(article => {
    const title = encodeURIComponent(article.title);
    const url = `https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/${article.wiki}/all-access/all-agents/${title}/daily/${startDate}/${endDate}`;
    viewPerArticle.push(new Promise((res, rej) => {
      return $.ajax({
        type: 'GET',
        url: url,
        Accept: 'application/json; charset=utf-8',
        success(data) {
          return res(data);
        }
      })
        .fail((obj) => {
          logErrorMessage(obj);
          return rej(obj);
        });
    }));
    return null;
  });
  return viewPerArticle;
};

export const setUploadPageViews = (articleList) => dispatch => {
  return (
    Promise.all(fetchUploadPageViews(articleList))
      .then(resp => dispatch({
        type: SET_UPLOAD_PAGEVIEWS,
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
