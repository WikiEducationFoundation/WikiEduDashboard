import _ from 'lodash';
import promiseLimit from 'promise-limit';
import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, API_FAIL } from "../constants";
import { queryUrl, categoryQueryGenerator, pageviewQueryGenerator, pageAssessmentQueryGenerator, pageRevisionQueryGenerator, pageRevisionScoreQueryGenerator } from '../utils/article_finder_utils.js';

const mediawikiApiBase = 'https://en.wikipedia.org/w/api.php?action=query&format=json';
const oresApiBase = 'https://ores.wikimedia.org/v3/scores/enwiki';

const limit = promiseLimit(10);

export const fetchCategoryResults = (category, depth) => dispatch => {
  dispatch({
    type: CLEAR_FINDER_STATE
  });
  return getDataForCategory(`Category:${category}`, depth, 0, dispatch)
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const getDataForCategory = (category, depth, namespace = 0, dispatch) => {
  const query = categoryQueryGenerator(category, namespace);
  return limit(() => queryUrl(mediawikiApiBase, query))
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
    fetchPageAssessment(data, dispatch);
  });
};

export const findSubcategories = (category) => {
  const subcatQuery = categoryQueryGenerator(category, 14);
  return limit(() => queryUrl(mediawikiApiBase, subcatQuery))
  .then((data) => {
    return data.query.categorymembers;
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
    const url = pageviewQueryGenerator(article.title);
    limit(() => queryUrl(url, {}, 'json'))
    .then((data) => data.items)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data: data
      });
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
  });
};

const fetchPageAssessment = (articlesList, dispatch) => {
  const promises = _.chunk(articlesList, 20).map((articles) => {
    const query = pageAssessmentQueryGenerator(_.map(articles, 'title'));

    return limit(() => queryUrl(mediawikiApiBase, query))
    .then((data) => data.query.pages)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_PAGEASSESSMENT,
        data: data
      });
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
  });

  Promise.all(promises)
  .then(() => {
    fetchPageRevision(articlesList, dispatch);
  });
};

const fetchPageRevision = (articlesList, dispatch) => {
  const promises = _.chunk(articlesList, 20).map((articles) => {
    const query = pageRevisionQueryGenerator(_.map(articles, 'title'));
    return limit(() => queryUrl(mediawikiApiBase, query))
    .then((data) => data.query.pages)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_REVISION,
        data: data
      });
      return data;
    })
    .then((data) => {
      return fetchPageRevisionScore(data, dispatch);
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
  });
  Promise.all(promises)
  .then(() => {
    fetchPageViews(articlesList, dispatch);
  });
};

const fetchPageRevisionScore = (revids, dispatch) => {
    const query = pageRevisionScoreQueryGenerator(_.map(revids, (revid) => {
      return revid.revisions[0].revid;
    }));
    return limit(() => queryUrl(oresApiBase, query))
    .then((data) => data.enwiki.scores)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_REVISIONSCORE,
        data: data
      });
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
};
