import _ from 'lodash';
import promiseLimit from 'promise-limit';
import { UPDATE_FIELD, RECEIVE_CATEGORY_RESULTS, RECEIVE_PSID_RESULTS, CLEAR_FINDER_STATE, INITIATE_SEARCH, RECEIVE_ARTICLE_PAGEVIEWS, RECEIVE_ARTICLE_PAGEASSESSMENT, RECEIVE_ARTICLE_REVISION, RECEIVE_ARTICLE_REVISIONSCORE, SORT_ARTICLE_FINDER, RECEIVE_KEYWORD_RESULTS, API_FAIL, CLEAR_RESULTS } from '../constants';
import { queryUrl, categoryQueryGenerator, pageviewQueryGenerator, pageAssessmentQueryGenerator, pageRevisionQueryGenerator, pageRevisionScoreQueryGenerator, keywordQueryGenerator } from '../utils/article_finder_utils.js';
import { ORESSupportedWiki, PageAssessmentSupportedWiki } from '../utils/article_finder_language_mappings.js';

const mediawikiApiBase = (language, project) => {
  if (project === 'wikidata') {
    return `https://${project}.org/w/api.php?action=query&format=json`;
  }
  return `https://${language}.${project}.org/w/api.php?action=query&format=json`;
};

const petScanApi = (PSID) => {
  return `https://petscan.wmflabs.org/?psid=${PSID}&format=json`;
};

const oresApiBase = (language, project) => {
  if (project === 'wikidata') {
    return `https://ores.wikimedia.org/v3/scores/${project}wiki`;
  }
  return `https://ores.wikimedia.org/v3/scores/${language}wiki`;
};

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

export const fetchCategoryResults = (category, home_wiki, cmcontinue = '', continueResults = false) => (dispatch, getState) => {
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
  return getDataForCategory(`Category:${category}`, home_wiki, cmcontinue, 0, dispatch, getState);
};

const getDataForCategory = (category, home_wiki, cmcontinue, namespace = 0, dispatch, getState) => {
  const query = categoryQueryGenerator(category, cmcontinue, namespace);
  return limit(() => queryUrl(mediawikiApiBase(home_wiki.language, home_wiki.project), query))
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
    fetchPageAssessment(data, home_wiki, dispatch, getState, 'category');
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

const fetchPageViews = (articlesList, home_wiki, dispatch, getState, type) => {
  let query;
  const promises = _.chunk(articlesList, 5).map((articles) => {
    if (type === 'PSID') {
      query = pageviewQueryGenerator(_.map(articles, 'id'));
    } else {
      query = pageviewQueryGenerator(_.map(articles, 'pageid'));
    }
    return limit(() => queryUrl(mediawikiApiBase(home_wiki.language, home_wiki.project), query))
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

const titles = [];

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function replaceAll(str, term, replacement) {
  return str.replace(new RegExp(escapeRegExp(term), 'g'), replacement);
}

let titles_articles = [];

const fetchPageAssessment = (articlesList, home_wiki, dispatch, getState, type) => {
  if (PageAssessmentSupportedWiki[home_wiki.project] && _.includes(PageAssessmentSupportedWiki[home_wiki.project], home_wiki.language)) {
    let query;
    if (type === 'PSID') {
      articlesList.forEach((element) => {
        titles.push(replaceAll(element.title, '_', ' '));
      });
      titles_articles = titles;
    } else {
      titles_articles = articlesList;
    }
    const promises = _.chunk(titles_articles, 20).map((articles) => {
      if (type === 'PSID') {
        query = pageAssessmentQueryGenerator(articles);
      } else {
        query = pageAssessmentQueryGenerator(_.map(articles, 'title'));
      }
      return limit(() => queryUrl(mediawikiApiBase(home_wiki.language, home_wiki.project), query))
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
      fetchPageRevision(articlesList, home_wiki, dispatch, getState, type);
    });
  } else {
    fetchPageRevision(articlesList, home_wiki, dispatch, getState, type);
  }
};

const fetchPageRevision = (articlesList, home_wiki, dispatch, getState, type) => {
  if (_.includes(ORESSupportedWiki.languages, home_wiki.language) && _.includes(ORESSupportedWiki.projects, home_wiki.project)) {
    let query;
    if (type === 'PSID') {
      titles_articles = titles;
    } else {
      titles_articles = articlesList;
    }
    const promises = _.chunk(titles_articles, 20).map((articles) => {
      if (type === 'PSID') {
        query = pageRevisionQueryGenerator(articles);
      } else {
        query = pageRevisionQueryGenerator(_.map(articles, 'title'));
      }
      return limit(() => queryUrl(mediawikiApiBase(home_wiki.language, home_wiki.project), query))
      .then(data => data.query.pages)
      .then((data) => {
        dispatch({
          type: RECEIVE_ARTICLE_REVISION,
          data: data
        });
        return data;
      })
      .then((data) => {
        return fetchPageRevisionScore(data, home_wiki, dispatch);
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })));
    });
    Promise.all(promises)
    .then(() => {
      fetchPageViews(articlesList, home_wiki, dispatch, getState, type);
    });
  } else {
    fetchPageViews(articlesList, home_wiki, dispatch, getState, type);
  }
};

const fetchPageRevisionScore = (revids, home_wiki, dispatch) => {
  const query = pageRevisionScoreQueryGenerator(_.map(revids, (revid) => {
    return revid.revisions[0].revid;
  }), home_wiki.project);
  return promiseLimit(4)(() => queryUrl(oresApiBase(home_wiki.language, home_wiki.project), query))
  .then(data => data[`${home_wiki.project === 'wikidata' ? 'wikidata' : home_wiki.language}wiki`].scores)
  .then((data) => {
    dispatch({
      type: RECEIVE_ARTICLE_REVISIONSCORE,
      data: {
        data: data,
        language: home_wiki.language,
        project: home_wiki.project,
      }
    });
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

export const fetchPSIDResults = (PSID, home_wiki) => (dispatch, getState) => {
  dispatch({
    type: UPDATE_FIELD,
    data: {
      key: 'fetchState',
      value: 'ARTICLES_LOADING',
    }
  });
  return getDataForPSID(PSID, home_wiki, dispatch, getState);
};

const getDataForPSID = (PSID, home_wiki, dispatch, getState) => {
  return limit(() => queryUrl(petScanApi(PSID)))
  .then((data) => {
    dispatch({
      type: RECEIVE_PSID_RESULTS,
      data: data,
    });
    return data['*'][0].a['*'];
  })
  .then((data) => {
    fetchPageAssessment(data, home_wiki, dispatch, getState, 'PSID');
  })
  .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

export const fetchKeywordResults = (keyword, home_wiki, offset = 0, continueResults = false) => (dispatch, getState) => {
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
  return limit(() => queryUrl(mediawikiApiBase(home_wiki.language, home_wiki.project), query))
  .then((data) => {
    dispatch({
      type: RECEIVE_KEYWORD_RESULTS,
      data: data,
    });
    return data.query.search;
  })
  .then((articles) => {
    return fetchPageAssessment(articles, home_wiki, dispatch, getState, 'keyword');
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
