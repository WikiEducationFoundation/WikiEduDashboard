import { RECEIVE_UPLOADS, SORT_UPLOADS, SET_VIEW, API_FAIL } from '../constants';
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

export const sortUploads = key => ({ type: SORT_UPLOADS, key: key });

export const setView = view => ({ type: SET_VIEW, view: view });
