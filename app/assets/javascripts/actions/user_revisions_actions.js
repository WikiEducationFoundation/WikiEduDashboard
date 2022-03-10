import { RECEIVE_USER_REVISIONS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';


const fetchUserRevisionsPromise = async (courseId, userId) => {
  const response = await request(`/revisions.json?user_id=${userId}&course_id=${courseId}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const fetchUserRevisions = (courseId, userId) => (dispatch, getState) => {
  // Don't refetch a user's revisions if they are already in the store.
  if (getState().userRevisions[userId]) { return; }

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

