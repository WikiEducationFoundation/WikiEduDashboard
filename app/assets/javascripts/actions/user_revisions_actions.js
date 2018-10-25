import { RECEIVE_USER_REVISIONS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';

const fetchUserRevisionsPromise = (courseId, userId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/revisions.json?user_id=${userId}&course_id=${courseId}`,
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

export const fetchUserRevisions = (courseId, userId) => (dispatch) => {
  return (
    fetchUserRevisionsPromise(courseId, userId)
      .then((resp) => {
        dispatch({
          type: RECEIVE_USER_REVISIONS,
          data: resp,
          userId
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

