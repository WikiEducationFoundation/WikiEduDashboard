import { RECEIVE_CATEGORIES, ADD_CATEGORY, DELETE_CATEGORY, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import { stringify } from 'query-string';

const fetchCategoriesPromise = async (courseSlug) => {
  const response = await request(`/courses/${courseSlug}/categories.json`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
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

const addCategoryPromise = async ({ category, source, project, language, depth, course }) => {
  const params = {
    category_name: category,
    depth,
    course_id: course.id,
    project,
    language,
    source
  };

  const response = await request(`/categories.json?${stringify(params)}`, {
    method: 'POST'
  });

  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
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

const removeCategoryPromise = async (course_id, category_id) => {
  const params = {
    category_id,
    course_id
  };

  const response = await request(`/categories.json?${stringify(params)}`, {
    method: 'DELETE'
  });

  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw data;
  }
  return response.json();
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
