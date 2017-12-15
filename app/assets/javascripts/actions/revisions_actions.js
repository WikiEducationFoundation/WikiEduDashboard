import { RECEIVE_REVISIONS, SORT_REVISIONS } from "../constants";
import ApiFailAction from "./api_fail_action.js";
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
      // TODO: The Flux stores still handle API failures, so we delegate to a
      // Flux action. Once all API_FAIL actions can be handled by Redux, we can
      // replace this with a regular action dispatch.
      .catch(response => ApiFailAction.fail(response))
  );
};

export const sortRevisions = key => ({ type: SORT_REVISIONS, key: key });
