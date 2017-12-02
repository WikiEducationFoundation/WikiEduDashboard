import ApiFailAction from "./api_fail_action.js";
import { RECEIVE_CATEGORIES, ADD_CATEGORY, DELETE_CATEGORY } from "../constants";
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
      // TODO: The Flux stores still handle API failures, so we delegate to a
      // Flux action. Once all API_FAIL actions can be handled by Redux, we can
      // replace this with a regular action dispatch.
      .catch(response => ApiFailAction.fail(response))
  );
};

const addCategoryPromise = (courseId, categoryName, depth) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'POST',
      url: `/categories.json?category_name=${categoryName}&depth=${depth}&course_id=${courseId}`,
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

export const addCategory = (courseId, categoryName, depth) => dispatch => {
  return (
    addCategoryPromise(courseId, categoryName, depth)
      .then(resp =>
        dispatch({
          type: ADD_CATEGORY,
          data: resp,
        }))
      // TODO: The Flux stores still handle API failures, so we delegate to a
      // Flux action. Once all API_FAIL actions can be handled by Redux, we can
      // replace this with a regular action dispatch.
      .catch(response => ApiFailAction.fail(response))
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
      // TODO: The Flux stores still handle API failures, so we delegate to a
      // Flux action. Once all API_FAIL actions can be handled by Redux, we can
      // replace this with a regular action dispatch.
      .catch(response => ApiFailAction.fail(response))
  );
};
