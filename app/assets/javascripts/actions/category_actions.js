import { RECEIVE_CATEGORIES, ADD_CATEGORY, DELETE_CATEGORY, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import fetch from 'cross-fetch';

const fetchCategoriesPromise = (courseSlug) => {
  return fetch(`/courses/${courseSlug}/categories.json`, {
    credentials: 'include'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

export const fetchCategories = courseSlug => (dispatch) => {
  return (
    fetchCategoriesPromise(courseSlug)
      .then(resp =>
        dispatch({
          type: RECEIVE_CATEGORIES,
          data: resp,
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

const addCategoryPromise = ({ category, source, project, language, depth, course }) => {
  return fetch(`/categories.json?category_name=${category}&depth=${depth}&course_id=${course.id}&project=${project}&language=${language}&source=${source}`, {
    credentials: 'include',
    method: 'POST'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

export const addCategory = categoryCourse => (dispatch) => {
  return (
    addCategoryPromise(categoryCourse)
      .then(resp =>
        dispatch({
          type: ADD_CATEGORY,
          data: resp,
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

const removeCategoryPromise = (courseId, categoryId) => {
  return fetch(`/categories.json?category_id=${categoryId}&course_id=${courseId}`, {
    credentials: 'include',
    method: 'DELETE'
  }).then((res) => {
    if (res.ok && res.status === 200) {
      return res.json();
    }
    return Promise.reject(res);
  })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

export const removeCategory = (courseId, categoryId) => (dispatch) => {
  return (
    removeCategoryPromise(courseId, categoryId)
      .then(resp =>
        dispatch({
          type: DELETE_CATEGORY,
          data: resp,
        }))
        .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
