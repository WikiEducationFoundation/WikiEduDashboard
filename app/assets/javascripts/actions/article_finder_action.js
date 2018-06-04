import _ from 'lodash';
import promiseLimit from 'promise-limit';
import { UPDATE_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, RECEIVE_KEYWORD_RESULTS, API_FAIL } from "../constants";
import { queryUrl, categoryQueryGenerator, pageviewQueryGenerator, pageAssessmentQueryGenerator, pageRevisionQueryGenerator, pageRevisionScoreQueryGenerator, keywordQueryGenerator } from '../utils/article_finder_utils.js';
import { getFilteredArticleFinderByQuality } from '../selectors';

const mediawikiApiBase = 'https://en.wikipedia.org/w/api.php?action=query&format=json';
const oresApiBase = 'https://ores.wikimedia.org/v3/scores/enwiki';

const limit = promiseLimit(10);

export const updateFields = (key, value) => (dispatch, getState) => {
  dispatch({
    type: UPDATE_FIELD,
    data: {
      key: key,
      value: value,
    },
  });

  const filters = ["min_views", "max_completeness", "grade"];
  if (_.includes(filters, key)) {
    fetchPageRevision(dispatch, getState);
  }
};

export const sortArticleFinder = (key) => {
  return {
    type: SORT_ARTICLE_FINDER,
    key: key,
  };
};

export const fetchCategoryResults = (category, depth) => (dispatch, getState) => {
  dispatch({
    type: CLEAR_FINDER_STATE,
  });
  return getDataForCategory(`Category:${category}`, depth, 0, dispatch, getState);
};

const getDataForCategory = (category, depth, namespace = 0, dispatch, getState) => {
  const query = categoryQueryGenerator(category, namespace);
  return limit(() => queryUrl(mediawikiApiBase, query))
  .then((data) => {
    if (depth > 0) {
        depth -= 1;
        getDataForSubCategories(category, depth, namespace, dispatch, getState);
      }
    dispatch({
      type: RECEIVE_CATEGORY_RESULTS,
      data: data.query.categorymembers
    });
    return data.query.categorymembers;
  })
  .then((data) => {
    fetchPageAssessment(data, dispatch, getState);
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

export const findSubcategories = (category) => {
  const subcatQuery = categoryQueryGenerator(category, 14);
  return limit(() => queryUrl(mediawikiApiBase, subcatQuery))
  .then((data) => {
    return data.query.categorymembers;
  });
};

const getDataForSubCategories = (category, depth, namespace, dispatch, getState) => {
  return findSubcategories(category)
  .then((subcats) => {
    subcats.forEach((subcat) => {
      getDataForCategory(subcat.title, depth, namespace, dispatch, getState);
    });
  });
};

const fetchPageViews = (dispatch, getState) => {
  const articles = getFilteredArticleFinderByQuality(getState());
  _.forEach(articles, (article) => {
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

const fetchPageAssessment = (articlesList, dispatch, getState) => {
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
    fetchPageRevision(articlesList, dispatch, getState);
  });
};

const fetchPageRevision = (articlesList, dispatch, getState) => {
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
    fetchPageViews(dispatch, getState);
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


export const fetchKeywordResults = (keyword, offset, continueResults = false) => (dispatch, getState) => {
  if (!continueResults) {
    dispatch({
      type: CLEAR_FINDER_STATE
    });
  }
  const query = keywordQueryGenerator(keyword, offset);
  return limit(() => queryUrl(mediawikiApiBase, query))
  .then((data) => {
    dispatch({
      type: RECEIVE_KEYWORD_RESULTS,
      data: data,
    });
    return data.query.search;
  })
  .then((articles) => {
    return fetchPageAssessment(articles, dispatch, getState);
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

