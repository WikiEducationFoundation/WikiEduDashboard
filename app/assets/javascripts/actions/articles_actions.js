import * as types from '../constants';
import logErrorMessage from '../utils/log_error_message';
import { fetchWikidataLabelsForArticles } from './wikidata_actions';
import request from '../utils/request';
import { DONE_REFRESHING_DATA } from '../constants';

const fetchArticlesPromise = (courseId, limit) => {
  return request(`/courses/${courseId}/articles.json?limit=${limit}`)
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
