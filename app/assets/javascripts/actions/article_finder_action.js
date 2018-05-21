import _ from 'lodash';
import { RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, API_FAIL } from "../constants";
import { queryUrl, categoryQueryGenerator, pageviewQueryGenerator, pageAssessmentQueryGenerator, pageRevisionQueryGenerator, pageRevisionScoreQueryGenerator } from '../utils/article_finder_utils.js';

const mediawikiApiBase = 'https://en.wikipedia.org/w/api.php?action=query&format=json';
const oresApiBase = 'https://ores.wikimedia.org/v3/scores/enwiki';
export const fetchCategoryResults = (category, depth) => dispatch => {
  dispatch({
    type: CLEAR_FINDER_STATE
  });
  return getDataForCategory(`Category:${category}`, depth, 0, dispatch)
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const getDataForCategory = (category, depth, namespace = 0, dispatch) => {
  const query = categoryQueryGenerator(category, namespace);
  return queryUrl(mediawikiApiBase, query)
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
    fetchPageRevision(data, dispatch);
  });
};

export const findSubcategories = (category) => {
  const subcatQuery = categoryQueryGenerator(category, 14);
  return queryUrl(mediawikiApiBase, subcatQuery)
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
    queryUrl(url, {}, 'json')
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
  queryUrl(mediawikiApiBase, query)
  .then((data) => data.query.pages)
  .then((data) => {
    _.forEach(data, (value) => {
      const title = value.title;
      const classGrade = extractClassGrade(value.pageassessments);
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

const fetchPageRevision = (articles, dispatch) => {
  const query = pageRevisionQueryGenerator(_.map(articles, 'title'));
  queryUrl(mediawikiApiBase, query)
  .then((data) => data.query.pages)
  .then((data) => {
    const revids = _.map(data, (page) => {
      return { title: page.title, revid: page.revisions[0].revid };
    });
    dispatch({
      type: RECEIVE_ARTICLE_REVISION,
      data: revids
    });
    return revids;
  })
  .then((revids) => {
    fetchPageRevisionScore(revids, dispatch);
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

const fetchPageRevisionScore = (revids, dispatch) => {
  const query = pageRevisionScoreQueryGenerator(_.map(revids, 'revid'));
  queryUrl(oresApiBase, query)
  .then((data) => data.enwiki.scores)
  .then((data) => {
    const WP10Weights = { FA: 100, GA: 80, B: 60, C: 40, Start: 20, Stub: 0 };
    const revScores = _.map(data, (scores, revid) => {
      const revScore = _.reduce(WP10Weights, (result, value, key) => {
        return result + value * scores.wp10.score.probability[key];
      }, 0);
      return { revid: revid, revScore: Math.round(revScore * 100) / 100 };
    });
    dispatch({
      type: RECEIVE_ARTICLE_REVISIONSCORE,
      data: revScores
    });
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};
