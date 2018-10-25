import _ from 'lodash';
import { RECEIVE_UPLOADS, SORT_UPLOADS, SET_VIEW, FILTER_UPLOADS, SET_UPLOAD_METADATA, API_FAIL, SET_UPLOAD_VIEWER_METADATA, SET_UPLOAD_PAGEVIEWS, RESET_UPLOAD_PAGEVIEWS } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import pageViewDateString from '../utils/uploads_pageviews_utils';

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

export const receiveUploads = courseId => (dispatch) => {
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
  _.forEach(uploads, (upload) => {
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

export const setUploadMetadata = uploadsList => (dispatch) => {
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

export const setUploadViewerMetadata = upload => (dispatch) => {
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

const zeroViewsResponse = { items: [{ views: 0 }] };

const fetchUploadPageViews = (articleList) => {
  const viewPerArticle = [];
  // To obtain the start date, decalare a date const, calculate 60 days from the date of today
  // and then format the date to YYYYMMDD
  // To obtain the end date format the date of today to YYYYMMDD
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 60);
  const formattedStartDate = pageViewDateString(startDate);
  const endDate = pageViewDateString(new Date());
  articleList.map((article) => {
    const title = encodeURIComponent(article.title);
    const url = `https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/${article.wiki}/all-access/all-agents/${title}/daily/${formattedStartDate}/${endDate}`;
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
          // The Wikimedia pageviews API responds with a 404 if there are zero pageviews
          // for the entire requested range.
          // Here, we assume that any 404 is because there are no pageviews, and return
          // a simple zero views mock response instead of throwing an error.
          if (obj.status === 404) { return res(zeroViewsResponse); }
          logErrorMessage(obj);
          return rej(obj);
        });
    }));
    return null;
  });
  return viewPerArticle;
};

export const setUploadPageViews = articleList => (dispatch) => {
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

export const resetUploadsViews = () => ({ type: RESET_UPLOAD_PAGEVIEWS });

export const sortUploads = key => ({ type: SORT_UPLOADS, key: key });

export const setView = view => ({ type: SET_VIEW, view: view });

export const setUploadFilters = selectedFilters => ({ type: FILTER_UPLOADS, selectedFilters: selectedFilters });
