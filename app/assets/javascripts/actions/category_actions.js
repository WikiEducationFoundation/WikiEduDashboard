import { RECEIVE_CATEGORIES, ADD_CATEGORY, DELETE_CATEGORY, API_FAIL } from "../constants";
import logErrorMessage from '../utils/log_error_message';

const fetchCategoriesPromise = (courseSlug) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseSlug}/categories.json`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  }
  );
};

export const fetchCategories = (courseSlug) => dispatch => {
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
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'POST',
      url: `/categories.json?category_name=${category}&depth=${depth}&course_id=${course.id}&project=${project}&language=${language}&source=${source}`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  }
  );
};

export const addCategory = (categoryCourse) => dispatch => {
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
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'DELETE',
      url: `/categories.json?category_id=${categoryId}&course_id=${courseId}`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  }
  );
};

export const removeCategory = (courseId, categoryId) => dispatch => {
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
