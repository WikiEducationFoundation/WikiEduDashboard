import { RECEIVE_UPLOADS, SORT_UPLOADS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchUploads = (courseId, limit = 100) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/uploads.json?limit=` + limit,
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

export const receiveUploads = (courseId, limit) => dispatch => {
  return (
    fetchUploads(courseId, limit)
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
