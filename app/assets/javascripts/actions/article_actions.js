import * as types from '../constants';
import API from '../utils/api.js';
import { getRevisionRange } from '../utils/mediawiki_revisions_utils';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch function —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function fetchArticleDetails(articleId, courseId, articleTitle, article_mw_page_id) {
  return async function (dispatch) {
    const crossCheckedArticleTitle = await dispatch(crossCheckArticleTitle(articleId, articleTitle, article_mw_page_id));
    const wikipediaArticleTitle = crossCheckedArticleTitle === articleTitle ? articleTitle : crossCheckedArticleTitle;

    return API.fetchArticleDetails(articleId, courseId)
      .then((response) => {
        const details = response.article_details;
        return getRevisionRange(details.apiUrl, wikipediaArticleTitle, details.editors, details.startDate, details.endDate)
          .then(revisionRange => dispatch({ type: types.RECEIVE_ARTICLE_DETAILS, articleId, details, revisionRange }));
      })
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export function updateArticleTrackedStatus(articleId, courseId, tracked) {
  return function (dispatch) {
    return API.updateArticleTrackedStatus(articleId, courseId, tracked).then(response => (dispatch({
      type: types.UPDATE_ARTICLE_TRACKED_STATUS,
      articleId,
      tracked,
      data: response
    }))).catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

export const crossCheckArticleTitle = (articleId, articleTitle, article_mw_page_id) => {
  return async (dispatch) => {
    try {
      // Fetch the page title from Wikipedia API
      const response = await fetch(
        `https://en.wikipedia.org/w/api.php?action=query&pageids=${article_mw_page_id}&format=json&origin=*`
      );

      if (!response.ok) {
        throw new Error(`API request failed with status ${response.status}`);
      }

      const apiResponse = await response.json();
      const wikipediaArticleTitle = apiResponse.query.pages[article_mw_page_id]?.title;

      if (wikipediaArticleTitle && wikipediaArticleTitle !== articleTitle) {
        const baseUrl = 'https://en.wikipedia.org/wiki/';
        const updatedUrl = `${baseUrl}${wikipediaArticleTitle.replace(/ /g, '_')}`;

        dispatch({
          type: types.UPDATE_ARTICLE_TITLE_AND_URL,
          payload: { articleId, title: wikipediaArticleTitle, url: updatedUrl },
        });

        return wikipediaArticleTitle;
      }

      return articleTitle;
    } catch (error) {
      dispatch({ type: types.API_FAIL, data: error });
    }
  };
};
