import {
  RECEIVE_NEWS_CONTENT_LIST,
  UPDATE_NEWS_CONTENT,
  CANCEL_NEWS_UPDATE,
  PERSIST_NEWS_CONTENT,
  DELETE_NEWS_CONTENT,
  CREATE_NEWS_CONTENT,
  RESET_CREATE_NEWS_CONTENT,
  ADD_NEWS_TO_LIST,
} from '../constants';
import logErrorMessage from '../utils/log_error_message';
import API from '../utils/api';
import { find } from 'lodash';

// Fetch all news content from the server
export const fetchAllNewsContent = () => async (dispatch) => {
  try {
    // Fetch the news content list from the API
    const newsContentList = await API.fetchNews();

    // Dispatch an action to store the fetched news content list in the Redux store
    dispatch({ type: RECEIVE_NEWS_CONTENT_LIST, news_content_list: newsContentList });

    return true;
  } catch (error) {
    // Log an error message if fetching fails
    logErrorMessage('Error fetching news content:', error);
  }
};

// Create or cache new news content
export const createNewsContent = (newsContent, post = false) => async (dispatch, getState) => {
  if (post) {
    try {
      // If `post` is true, create news on the server
      const newsDetails = await API.createNews(getState().news.create_news);
      if (newsDetails?.id) {
        // If the creation is successful, dispatch actions to add the new news to the list and persist the updated list
        dispatch({ type: ADD_NEWS_TO_LIST, newNews: newsDetails });
        dispatch({ type: PERSIST_NEWS_CONTENT, news_content_list: getState().news.news_content_list });
        return newsDetails;
      }
    } catch (error) {
      // Log an error message if fetching fails
      logErrorMessage('Error creating news content:', error);
    }
  }
  // If `post` is false, cache the new news content locally
  dispatch({ type: CREATE_NEWS_CONTENT, content: newsContent });
};

// Cache edited news content locally
export const cacheNewsContentEdit = ({ content, id }) => (dispatch) => {
  dispatch({ type: UPDATE_NEWS_CONTENT, news: { content, id } });
};

// Cancel editing of news content and revert to persisted state
export const cancelNewsContentEditing = () => (dispatch, getState) => {
  // Get the persisted news content from the state
  const newsContent = getState().persistedNews;
  // Dispatch an action to cancel the update and revert to persisted news content
  dispatch({ type: CANCEL_NEWS_UPDATE, news_content: newsContent });
};

// Save edited news content to the server
export const saveEditedNewsContent = (newsId = null) => async (dispatch, getState) => {
  // Find the news item to be updated by its ID using lodash's `find` method
  const newsItem = find(getState().news.news_content_list, { id: newsId });
  const { id, content } = newsItem;

  try {
    // Call the API to update the news content on the server
    const status = await API.updateNews({ id, content });

    if (status?.id) {
      // If the update is successful, dispatch an action to persist the updated list
      dispatch({
        type: PERSIST_NEWS_CONTENT,
        news_content_list: getState().news.news_content_list
      });
      return status.id;
    }
  } catch (error) {
    // Log an error message if fetching fails
    logErrorMessage('Error fetching updating news content:', error);
  }
};

// Delete selected news content
export const deleteSelectedNewsContent = newsId => async (dispatch, getState) => {
  try {
    // Call the API to delete the news content by its ID
    const status = await API.deleteNews(newsId);

    if (status.id === newsId) {
      // If the deletion is successful, dispatch actions to remove the news from the list and persist the updated list
      dispatch({ type: DELETE_NEWS_CONTENT, news_id: newsId });
      dispatch({ type: PERSIST_NEWS_CONTENT, news_content_list: getState().news.news_content_list });
    }
  } catch (error) {
    // Log an error message if fetching fails
    logErrorMessage('Error fetching updating news content:', error);
  }
};

// Reset the state related to creating news content
export const resetCreateNewsState = () => (dispatch) => {
  dispatch({ type: RESET_CREATE_NEWS_CONTENT });
};
