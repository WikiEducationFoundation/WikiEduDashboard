import { RECEIVE_TAGS, RECEIVE_ALL_TAGS, ADD_TAG, REMOVE_TAG, API_FAIL } from '../constants';
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

export const fetchTags = courseId => (dispatch) => {
  return (
    fetchTagsPromise(courseId)
      .then((data) => {
        dispatch({
          type: RECEIVE_TAGS,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

const fetchAllTagsPromise = () => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: '/lookups/tag.json',
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

export const fetchAllTags = () => (dispatch) => {
  return fetchAllTagsPromise()
    .then(data => dispatch({ type: RECEIVE_ALL_TAGS, data }))
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const addTagPromise = (courseId, tag) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'POST',
      url: `/courses/${courseId}/tag.json`,
      data: { tag: { tag } },
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

export const addTag = (courseId, tag) => (dispatch) => {
  return (
    addTagPromise(courseId, tag)
      .then((data) => {
        dispatch({
          type: ADD_TAG,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

const removeTagPromise = (courseId, tag) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'DELETE',
      url: `/courses/${courseId}/tag.json`,
      data: { tag: { tag } },
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

export const removeTag = (courseId, tag) => (dispatch) => {
  return (
    removeTagPromise(courseId, tag)
      .then((data) => {
        dispatch({
          type: REMOVE_TAG,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
