import { RECEIVE_REVISIONS, SORT_REVISIONS, API_FAIL } from "../constants";
import logErrorMessage from '../utils/log_error_message';

const fetchRevisionsPromise = (courseId, limit) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/revisions.json?limit=${limit}`,
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

export const fetchRevisions = (courseId, limit) => dispatch => {
  return (
    fetchRevisionsPromise(courseId, limit)
      .then(resp =>
        dispatch({
          type: RECEIVE_REVISIONS,
          data: resp,
          limit: limit
        }))
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const sortRevisions = key => ({ type: SORT_REVISIONS, key: key });
