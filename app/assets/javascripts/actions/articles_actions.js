import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import { fetchWikidataLabelsForArticles } from './wikidata_actions';
import request from '../utils/request';
import { DONE_REFRESHING_DATA } from '../constants';

// The server returns at most this many articles per request. Asking for more
// than that at once is what used to make large courses hit the article cap.
const ARTICLES_PAGE_SIZE = 500;

const fetchArticlesPage = (courseId, pageSize, afterId) => {
  const afterParam = afterId ? `&after_id=${afterId}` : '';
  return request(`/courses/${courseId}/articles.json?limit=${pageSize}${afterParam}`)
    .then((res) => {
      if (res.ok && res.status === 200) {
        return res.json();
      }
      return Promise.reject(res);
    })
    .catch((error) => {
      logErrorMessage(error);
      return error;
    });
};

// Loads up to `limit` articles one page at a time, using the articles_course_id
// of the last article received as the cursor for the next page.
const fetchArticlesPromise = async (courseId, limit) => {
  let articles = [];
  let response = { course: {} };
  while (articles.length < limit) {
    const pageSize = Math.min(ARTICLES_PAGE_SIZE, limit - articles.length);
    const afterId = articles.length ? articles[articles.length - 1].articles_course_id : null;
    const pageResponse = await fetchArticlesPage(courseId, pageSize, afterId);
    const page = pageResponse?.course?.articles;
    // A failed request resolves to the error, which the caller already handles.
    if (!page) { return pageResponse; }
    response = pageResponse;
    articles = articles.concat(page);
    if (page.length < pageSize) { break; }
  }
  return { ...response, course: { ...response.course, articles } };
};

export const fetchArticles = (courseId, limit, refresh = false) => {
  return (dispatch) => {
    return fetchArticlesPromise(courseId, limit)
      .then((resp) => {
        dispatch({
          type: types.RECEIVE_ARTICLES,
          data: resp,
          limit,
        });
        dispatch({
          type: types.SORT_ARTICLES,
          key: 'character_sum',
          refresh,
        });
        if (refresh) {
          dispatch({ type: DONE_REFRESHING_DATA });
        }
        // Now that we received the articles data, query wikidata.org for the labels
        // of any Wikidata entries that are among the articles.
        fetchWikidataLabelsForArticles(resp.course.articles, dispatch);
      })
      .catch((response) => {
        dispatch({ type: types.API_FAIL, data: response });
      });
  };
};

export const sortArticles = (key, refresh) => ({
  type: types.SORT_ARTICLES,
  key,
  refresh,
});

export const filterArticles = wiki => ({
  type: types.SET_PROJECT_FILTER,
  wiki,
});

export const filterNewness = newness => ({
  type: types.SET_NEWNESS_FILTER,
  newness,
});

export const filterTrackedStatus = trackedStatus => ({
  type: types.SET_TRACKED_STATUS_FILTER,
  trackedStatus,
});
