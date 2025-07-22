import * as types from '../constants';
import API from '../utils/api.js';
import { getRevisionRange } from '../utils/mediawiki_revisions_utils';
import { find } from 'lodash-es';

// This action uses the Thunk middleware pattern: instead of returning a plain
// action object, it returns a function that takes the store dispatch function —
// which Thunk automatically provides — and can then dispatch a series of plain
// actions to be handled by the store.
// This is how actions with side effects — such as API calls — are handled in
// Redux.
export function fetchArticleDetails(articleId, courseId) {
  return async function (dispatch, getState) {
    return API.fetchArticleDetails(articleId, courseId)
      .then((response) => {
        const details = response.article_details;

        return getRevisionRange(details.apiUrl, details.articleTitle, details.editors, details.startDate, details.endDate)
          .then(async (revisionRange) => {
            // If no revisions are found (both first and last revisions are missing),
            // it may indicate a mismatch in the article title as the article was moved to a new title.
            if (!revisionRange.first_revision && !revisionRange.last_revision) {
              const { title: articleTitle, mw_page_id: article_mw_page_id } = find(
                getState().articles.articles,
                { id: articleId }
              ) || {};

              // Dispatch an action to cross-check the article title with its metadata.
              if (articleId && articleTitle && article_mw_page_id) {
                const crossCheckedArticleTitle = await dispatch(crossCheckArticleTitle(articleId, articleTitle, article_mw_page_id));

                // Re-fetch the article details using the cross-checked title for accuracy.
                fetchArticleDetailsAgain(crossCheckedArticleTitle, articleId, courseId, dispatch);
              }
            } else {
              dispatch({ type: types.RECEIVE_ARTICLE_DETAILS, articleId, details, revisionRange });
            }
          });
      })
      .catch(response => (dispatch({ type: types.API_FAIL, data: response })));
  };
}

// Re-fetches article details using the corrected or cross-checked article title.
// This function is used when the initial fetch fails to retrieve valid revision data,
// likely due to a mismatch in the article title. It ensures the Redux store is updated
// with accurate article details and revision ranges after the re-fetch.
function fetchArticleDetailsAgain(crossCheckedArticleTitle, articleId, courseId, dispatch) {
  return API.fetchArticleDetails(articleId, courseId)
    .then((response) => {
      const details = response.article_details;

      // Calculate the revision range for the updated article title.
      return getRevisionRange(
        details.apiUrl,
        crossCheckedArticleTitle,
        details.editors,
        details.startDate,
        details.endDate
      ).then((revisionRange) => {
          // Dispatch the updated article details and revision range to Redux.
          dispatch({ type: types.RECEIVE_ARTICLE_DETAILS, articleId, details, revisionRange });
      });
    })
    .catch((response) => {
      (dispatch({ type: types.API_FAIL, data: response }));
    });
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
