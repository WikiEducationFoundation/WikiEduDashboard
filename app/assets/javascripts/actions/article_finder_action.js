import _ from 'lodash';
import promiseLimit from 'promise-limit';
import { UPDATE_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, INITIATE_SEARCH, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, RECEIVE_KEYWORD_RESULTS, API_FAIL } from '../constants';
import { queryUrl, categoryQueryGenerator, pageviewQueryGenerator, pageAssessmentQueryGenerator, pageRevisionQueryGenerator, pageRevisionScoreQueryGenerator, keywordQueryGenerator } from '../utils/article_finder_utils.js';
import { ORESSupportedWiki, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings.js';

const mediawikiApiBase = (language, project) => (`https://${language}.${project}.org/w/api.php?action=query&format=json`);
const oresApiBase = language => (`https://ores.wikimedia.org/v3/scores/${language}wiki`);

const limit = promiseLimit(10);

export const updateFields = (key, value) => (dispatch) => {
  dispatch({
    type: UPDATE_FIELD,
    data: {
      key: key,
      value: value,
    },
  });
};

export const sortArticleFinder = (key) => {
  return {
    type: SORT_ARTICLE_FINDER,
    key: key,
  };
};

export const fetchCategoryResults = (category, course, cmcontinue = '', continueResults = false) => (dispatch, getState) => {
  if (!continueResults) {
    dispatch({
      type: INITIATE_SEARCH,
    });
  } else {
    dispatch({
      type: UPDATE_FIELD,
      data: {
        key: 'fetchState',
        value: 'ARTICLES_LOADING',
      }
    });
  }
  return getDataForCategory(`Category:${category}`, course, cmcontinue, 0, dispatch, getState);
};

const getDataForCategory = (category, course, cmcontinue, namespace = 0, dispatch, getState) => {
  const query = categoryQueryGenerator(category, cmcontinue, namespace);
  return limit(() => queryUrl(mediawikiApiBase(course.home_wiki.language, course.home_wiki.project), query))
  .then((data) => {
    // if (depth > 0) {
    //     depth -= 1;
    //     getDataForSubCategories(category, depth, namespace, dispatch, getState);
    //   }
    dispatch({
      type: RECEIVE_CATEGORY_RESULTS,
      data: data,
    });
    return data.query.categorymembers;
  })
  .then((data) => {
    fetchPageAssessment(data, course, dispatch, getState);
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

// export const findSubcategories = (category) => {
//   const subcatQuery = categoryQueryGenerator(category, 14);
//   return limit(() => queryUrl(mediawikiApiBase, subcatQuery))
//   .then((data) => {
//     return data.query.categorymembers;
//   });
// };

// const getDataForSubCategories = (category, depth, namespace, dispatch, getState) => {
//   return findSubcategories(category)
//   .then((subcats) => {
//     subcats.forEach((subcat) => {
//       getDataForCategory(subcat.title, depth, namespace, dispatch, getState);
//     });
//   });
// };

const fetchPageViews = (articlesList, course, dispatch, getState) => {
  const promises = _.chunk(articlesList, 5).map((articles) => {
    const query = pageviewQueryGenerator(_.map(articles, 'pageid'));
    return limit(() => queryUrl(mediawikiApiBase(course.home_wiki.language, course.home_wiki.project), query))
    .then(data => data.query.pages)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data: data
      });
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
  });
  const sort = getState().articleFinder.sort;
  let desc = false;
  if (!sort.key) {
    sort.key = 'relevanceIndex';
  } else if (!sort.sortKey) {
    desc = true;
  }
  Promise.all(promises)
  .then(() => {
    dispatch({
      type: SORT_ARTICLE_FINDER,
      key: sort.key,
      initial: true,
      desc: desc,
    });
  });
};

const fetchPageAssessment = (articlesList, course, dispatch, getState) => {
  if (_.includes(PageAssessmentSupportedWiki.languages, course.home_wiki.language) && course.home_wiki.project === 'wikipedia') {
    const promises = _.chunk(articlesList, 20).map((articles) => {
      const query = pageAssessmentQueryGenerator(_.map(articles, 'title'));

      return limit(() => queryUrl(mediawikiApiBase(course.home_wiki.language, course.home_wiki.project), query))
      .then(data => data.query.pages)
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
      fetchPageRevision(articlesList, course, dispatch, getState);
    });
  } else {
    fetchPageRevision(articlesList, course, dispatch, getState);
  }
};

const fetchPageRevision = (articlesList, course, dispatch, getState) => {
  if (_.includes(ORESSupportedWiki.languages, course.home_wiki.language) && course.home_wiki.project === 'wikipedia') {
    const promises = _.chunk(articlesList, 20).map((articles) => {
      const query = pageRevisionQueryGenerator(_.map(articles, 'title'));
      return limit(() => queryUrl(mediawikiApiBase(course.home_wiki.language, course.home_wiki.project), query))
      .then(data => data.query.pages)
      .then((data) => {
        dispatch({
          type: RECEIVE_ARTICLE_REVISION,
          data: data
        });
        return data;
      })
      .then((data) => {
        return fetchPageRevisionScore(data, course, dispatch);
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })));
    });
    Promise.all(promises)
    .then(() => {
      fetchPageViews(articlesList, course, dispatch, getState);
    });
  } else {
    fetchPageViews(articlesList, course, dispatch, getState);
  }
};

const fetchPageRevisionScore = (revids, course, dispatch) => {
    const query = pageRevisionScoreQueryGenerator(_.map(revids, (revid) => {
      return revid.revisions[0].revid;
    }));
    return promiseLimit(4)(() => queryUrl(oresApiBase(course.home_wiki.language), query))
    .then(data => data[`${course.home_wiki.language}wiki`].scores)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_REVISIONSCORE,
        data: {
          data: data,
          language: course.home_wiki.language
        }
      });
    })
    .catch(response => (dispatch({ type: API_FAIL, data: response })));
};


export const fetchKeywordResults = (keyword, course, offset = 0, continueResults = false) => (dispatch, getState) => {
  if (!continueResults) {
    dispatch({
      type: INITIATE_SEARCH
    });
  } else {
    dispatch({
      type: UPDATE_FIELD,
      data: {
        key: 'fetchState',
        value: 'ARTICLES_LOADING',
      }
    });
  }
  const query = keywordQueryGenerator(keyword, offset);
  return limit(() => queryUrl(mediawikiApiBase(course.home_wiki.language, course.home_wiki.project), query))
  .then((data) => {
    dispatch({
      type: RECEIVE_KEYWORD_RESULTS,
      data: data,
    });
    return data.query.search;
  })
  .then((articles) => {
    return fetchPageAssessment(articles, course, dispatch, getState);
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

export const resetArticleFinder = () => {
  return {
    type: CLEAR_FINDER_STATE,
  };
};
