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

const fetchPageAssessment = (articlesList, dispatch) => {
  const promises = _.chunk(articlesList, 20).map((articles) => {
    const query = pageAssessmentQueryGenerator(_.map(articles, 'title'));

    return limit(() => queryUrl(mediawikiApiBase, query))
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
  });

  Promise.all(promises)
  .then(() => {
    fetchPageRevision(articlesList, dispatch);
  });
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

const fetchPageRevision = (articlesList, dispatch) => {
  const promises = _.chunk(articlesList, 20).map((articles) => {
    const query = pageRevisionQueryGenerator(_.map(articles, 'title'));
    return limit(() => queryUrl(mediawikiApiBase, query))
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
      return fetchPageRevisionScore(revids, dispatch);
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
  });
  Promise.all(promises)
  .then(() => {
    fetchPageViews(articlesList, dispatch);
  });
};

const fetchPageRevisionScore = (revids, dispatch) => {
    const query = pageRevisionScoreQueryGenerator(_.map(revids, 'revid'));
    return limit(() => queryUrl(oresApiBase, query))
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
