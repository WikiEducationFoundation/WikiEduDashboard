import { RECEIVE_TAGS, RECEIVE_ALL_TAGS, ADD_TAG, REMOVE_TAG, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const fetchTagsPromise = async (courseId) => {
  const response = await request(`/courses/${courseId}/tags.json`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
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

const fetchAllTagsPromise = async () => {
  const response = await request('/lookups/tag.json');
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
};

export const fetchAllTags = () => (dispatch) => {
  return fetchAllTagsPromise()
    .then(data => dispatch({ type: RECEIVE_ALL_TAGS, data }))
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const addTagPromise = async (courseId, tag) => {
  const response = await request(`/courses/${courseId}/tag.json`, {
    method: 'POST',
    body: JSON.stringify({ tag: { tag } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
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

const removeTagPromise = async (courseId, tag) => {
  const response = await request(`/courses/${courseId}/tag.json`, {
    method: 'DELETE',
    body: JSON.stringify({ tag: { tag } })
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
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
