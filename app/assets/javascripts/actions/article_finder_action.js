import _ from 'lodash';
import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, API_FAIL } from "../constants";
import { queryMediaWiki, categoryQueryGenerator, findSubcategories, pageviewQueryGenerator, queryPageviews, pageAssessmentQueryGenerator, queryPageAssessment } from '../utils/article_finder_utils.js';

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
    return data.query.categorymembers;
  })
  .then((data) => {
    fetchPageViews(data, dispatch);
    fetchPageAssessment(data, dispatch);
  });
};

const getDataForSubCategories = (category, depth, namespace, dispatch) => {
  return findSubcategories(category)
  .then((subcats) => {
    subcats.forEach((subcat) => {
      getDataForCategory(subcat.title, depth, namespace, dispatch);
    });
  });
};

const fetchPageViews = (articles, dispatch) => {
  articles.forEach((article) => {
    const queryUrl = pageviewQueryGenerator(article.title);
    queryPageviews(queryUrl)
    .then((data) => data.items)
    .then((data) => {
      const averagePageviews = Math.round((_.sumBy(data, (o) => { return o.views; }) / data.length) * 100) / 100;
      return { title: data[0].article, pageviews: averagePageviews };
    })
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data: data
      });
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
  });
};

const fetchPageAssessment = (articles, dispatch) => {
  const query = pageAssessmentQueryGenerator(_.map(articles, 'title'));
  // console.log('query', query);
  queryPageAssessment(query)
  .then((data) => data.query.pages)
  .then((data) => {
    // console.log('DATA:', data);
    _.forEach(data, (value) => {
      // console.log('VALUE', value);
      const title = value.title;
      const classGrade = extractClassGrade(value.pageassessments);
      // console.log('Dispatched object:', { title: title, classGrade: classGrade });
      dispatch({
        type: RECEIVE_ARTICLE_PAGEASSESSMENT,
        data: { title: title, classGrade: classGrade }
      });
    });
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const extractClassGrade = (pageAssessments) => {
  let classGrade = '';
  _.forEach(pageAssessments, (pageAssessment) => {
    if (pageAssessment.class) {
      classGrade = pageAssessment.class;
      return false;
    }
  });
  return classGrade;
};
