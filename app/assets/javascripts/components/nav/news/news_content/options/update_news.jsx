import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { saveEditedNewsContent } from '@actions/news_action';
import { dispatchNotification } from '../../news_notification/notificationUtils';

// Component to trigger the update process of a news item
const UpdateNews = ({ saveEditedNews, newsId }) => {
  const [updateNews, setUpdateNews] = useState(false); // State to manage the icon hover effect

  // Retrieve the news item being currently edited from the Redux store based on the provided newsId
  const editedNews = useSelector(state => state.news.news_content_list.find(news => news.id === newsId));

  const dispatch = useDispatch();

  // Handle the update process for the edited news content
  function handleEditedNews() {
    if (!editedNews.content.trim().length) {
      dispatchNotification(dispatch, 'Error', I18n.t('news.notification.empty_update_news_content_error'));
    } else {
      try {
        dispatch(saveEditedNewsContent(newsId));
        saveEditedNews();
        dispatchNotification(dispatch, 'Success', I18n.t('news.notification.update'));
      } catch (error) {
        dispatchNotification(dispatch, 'Error', I18n.t('news.notification.update_error'));
      }
    }
  }

  return (
    <div
      onMouseEnter={() => setUpdateNews(true)} // Show blue icon on hover
      onMouseLeave={() => setUpdateNews(false)} // Revert to grey icon on mouse leave
      onClick={() => handleEditedNews()} // Trigger save action for edited news
      className="pop__padded-content news--content edit-news-options-padded-content delete-news"
    >
      {/* Display update icon, changing based on hover state */}
      <span className={updateNews ? 'icon-check icon-check--blue' : 'icon-check icon-check--grey'} />
      <p>{I18n.t('news.options.news_content.update_news')}</p>
    </div>
  );
};

export default UpdateNews;
