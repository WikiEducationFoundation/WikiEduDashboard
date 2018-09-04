import { RECEIVE_TAGS, API_FAIL } from "../constants";
import logErrorMessage from '../utils/log_error_message';

const fetchTagsPromise = (courseId) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/tags.json`,
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

export const fetchTags = courseId => dispatch => {
  return (
    fetchTagsPromise(courseId)
      .then(data => {
        dispatch({
          type: RECEIVE_TAGS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
