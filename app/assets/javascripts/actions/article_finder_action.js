import { chunk, map, includes } from 'lodash-es';
import promiseLimit from 'promise-limit';
import { UPDATE_FINDER_FIELD, RECEIVE_CATEGORY_RESULTS, CLEAR_FINDER_STATE, INITIATE_SEARCH, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, RECEIVE_KEYWORD_RESULTS, API_FAIL, CLEAR_RESULTS } from '../constants';
import { queryUrl, categoryQueryGenerator, pageviewQueryGenerator, pageAssessmentQueryGenerator, pageRevisionQueryGenerator, pageRevisionScoreQueryGenerator, keywordQueryGenerator } from '../utils/article_finder_utils.js';
import { ORESSupportedWiki, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings.js';
import { fetchWikidataLabels } from './wikidata_actions';
import request from '../utils/request';


const mediawikiApiBase = (language, project) => {
  if (project === 'wikidata') {
    return `https://${project}.org/w/api.php?action=query&format=json&origin=*`;
  }
  return `https://${language}.${project}.org/w/api.php?action=query&format=json&origin=*`;
};

const LIFT_WING_SERVER_URL = 'https://api.wikimedia.org';
const liftWingApiBase = (language, project) => {
  const project_code = project === 'wikidata' ? 'wikidatawiki' : `${language}wiki`;
  const project_quality_model = project === 'wikidata' ? 'itemquality' : 'articlequality';
  return `${LIFT_WING_SERVER_URL}/service/lw/inference/v1/models/${project_code}-${project_quality_model}:predict`;
};

const limit = promiseLimit(10);

export const updateFields = (key, value) => (dispatch) => {
  dispatch({
    type: UPDATE_FINDER_FIELD,
    data: {
      key,
      value,
    },
  });
};

export const sortArticleFinder = (key) => {
  return {
    type: SORT_ARTICLE_FINDER,
    key,
  };
};

export const fetchCategoryResults = (category, wiki, cmcontinue = '', continueResults = false) => (dispatch, getState) => {
  if (!continueResults) {
    dispatch({
      type: INITIATE_SEARCH,
    });
  } else {
    dispatch({
      type: UPDATE_FINDER_FIELD,
      data: {
        key: 'fetchState',
        value: 'ARTICLES_LOADING',
      }
    });
  }
  return getDataForCategory(`Category:${category}`, wiki, cmcontinue, 0, dispatch, getState);
};

const getDataForCategory = (category, wiki, cmcontinue, namespace = 0, dispatch, getState) => {
  const query = categoryQueryGenerator(category, cmcontinue, namespace);
  return limit(() => queryUrl(mediawikiApiBase(wiki.language, wiki.project), query))
  .then((data) => {
    // if (depth > 0) {
    //     depth -= 1;
    //     getDataForSubCategories(category, depth, namespace, dispatch, getState);
    //   }
    dispatch({
      type: RECEIVE_CATEGORY_RESULTS,
      data,
    });
    return data.query.categorymembers;
  })
  .then((data) => {
    fetchPageAssessment(data, wiki, dispatch, getState);
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

const fetchPageViews = (articlesList, wiki, dispatch, getState) => {
  const promises = chunk(articlesList, 5).map((articles) => {
    const query = pageviewQueryGenerator(map(articles, 'pageid'));
    return limit(() => queryUrl(mediawikiApiBase(wiki.language, wiki.project), query))
    .then(data => data.query.pages)
    .then((data) => {
      dispatch({
        type: RECEIVE_ARTICLE_PAGEVIEWS,
        data
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
      desc,
    });
  });
};

const fetchPageAssessment = (articlesList, wiki, dispatch, getState) => {
  if (PageAssessmentSupportedWiki[wiki.project] && includes(PageAssessmentSupportedWiki[wiki.project], wiki.language)) {
    const promises = chunk(articlesList, 20).map((articles) => {
      const query = pageAssessmentQueryGenerator(map(articles, 'title'));

      return limit(() => queryUrl(mediawikiApiBase(wiki.language, wiki.project), query))
      .then(data => data.query.pages)
      .then((data) => {
        dispatch({
          type: RECEIVE_ARTICLE_PAGEASSESSMENT,
          data
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })));
    });

    Promise.all(promises)
    .then(() => {
      fetchPageRevision(articlesList, wiki, dispatch, getState);
    });
  } else {
    fetchPageRevision(articlesList, wiki, dispatch, getState);
  }
};

const fetchPageRevision = (articlesList, wiki, dispatch, getState) => {
  if (includes(ORESSupportedWiki.languages, wiki.language) && includes(ORESSupportedWiki.projects, wiki.project)) {
    const promises = chunk(articlesList, 1).map((articles) => {
      const query = pageRevisionQueryGenerator(map(articles, 'title'));
      return limit(() => queryUrl(mediawikiApiBase(wiki.language, wiki.project), query))
      .then(data => data.query.pages)
      .then((data) => {
        dispatch({
          type: RECEIVE_ARTICLE_REVISION,
          data
        });
        return data;
      })
      .then((data) => {
        return fetchPageRevisionScore(data, wiki, dispatch);
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })));
    });
    Promise.all(promises)
    .then(() => {
      fetchPageViews(articlesList, wiki, dispatch, getState);
    });
  } else {
    fetchPageViews(articlesList, wiki, dispatch, getState);
  }
};

const fetchPageRevisionScore = async (revids, wiki, dispatch) => {
    const query = pageRevisionScoreQueryGenerator(map(revids, (revid) => {
      return revid.revisions[0].revid;
    }), wiki.project);

  const API_URL = liftWingApiBase(wiki.language, wiki.project);
  const params = {
    rev_id: Number(query.revids.split('|')[0]),
  };
  try {
    const response = await promiseLimit(5)(() =>
      request(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(params),
      })
    );

    if (!response.ok) {
      const data = await response.text();
      dispatch({ type: API_FAIL, data: response.responseText || data });
    }
    const responseJson = await response.json();
    const data = await responseJson[
      `${wiki.project === 'wikidata' ? 'wikidata' : wiki.language}wiki`
    ].scores;

    await dispatch({
      type: RECEIVE_ARTICLE_REVISIONSCORE,
      data: {
        data,
        language: wiki.language,
        project: wiki.project,
      },
    });
  } catch (error) {
    dispatch({ type: API_FAIL, data: error.message || error });
  }
};


export const fetchKeywordResults = (keyword, wiki, offset = 0, continueResults = false) => (dispatch, getState) => {
  if (!continueResults) {
    dispatch({
      type: INITIATE_SEARCH
    });
  } else {
    dispatch({
      type: UPDATE_FINDER_FIELD,
      data: {
        key: 'fetchState',
        value: 'ARTICLES_LOADING',
      }
    });
  }
  const query = keywordQueryGenerator(keyword, offset);
  return limit(() => queryUrl(mediawikiApiBase(wiki.language, wiki.project), query))
  .then((data) => {
    dispatch({
      type: RECEIVE_KEYWORD_RESULTS,
      data,
    });
    return data.query.search;
  })
  .then((articles) => {
    if (wiki.project === 'wikidata') fetchWikidataLabels(articles, dispatch);
    return fetchPageAssessment(articles, wiki, dispatch, getState);
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

export const resetArticleFinder = () => {
  return {
    type: CLEAR_FINDER_STATE,
  };
};

export const clearResults = () => {
  return {
    type: CLEAR_RESULTS,
  };
};
