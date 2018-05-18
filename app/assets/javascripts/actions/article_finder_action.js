import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, API_FAIL } from "../constants";
import { queryMediaWiki, categoryQueryGenerator, findSubcategories } from '../utils/article_finder_utils.js';

export const fetchCategoryResults = (category, depth) => dispatch => {
  dispatch({
    type: CLEAR_FINDER_STATE
  });
  return getDataForCategory(`Category:${category}`, depth, 0, dispatch)
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const getDataForCategory = (category, depth, namespace = 0, dispatch) => {
  const query = categoryQueryGenerator(category, namespace);
  return queryMediaWiki(query)
  .then((data) => {
    if (depth > 0) {
        depth -= 1;
        getDataForSubCategories(category, depth, namespace, dispatch);
      }
    dispatch({
      type: RECEIVE_CATEGORY_RESULTS,
      data: data.query.categorymembers
    });
  });
};

const getDataForSubCategories = (category, depth, namespace, dispatch) => {
  return findSubcategories(category)
  .then((subcats) => {
    const subcatPromises = [];
    subcats.forEach((subcat) => {
      subcatPromises.push(getDataForCategory(subcat.title, depth, namespace, dispatch));
    });
    return Promise.all(subcatPromises);
  })
  .then((values) => {
    return _.flatten(values);
  });
};
