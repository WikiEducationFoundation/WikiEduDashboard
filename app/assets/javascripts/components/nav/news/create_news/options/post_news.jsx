import React, { useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { dispatchNotification } from '../../news_notification/notificationUtils';

// Component to handle the posting of news
const PostNews = ({ postNews }) => {
  const [postNewsIcon, setPostNewsIcon] = useState(false); // State to manage the icon hover effect

  // Get the current news content from the Redux store
  // This value will be used to check if it's empty before posting the news
  const newsContent = useSelector(state => state.news.create_news.content);

  const dispatch = useDispatch();

  function handlePostNews() {
    if (!newsContent.trim().length) {
      dispatchNotification(dispatch, 'Error', I18n.t('news.notification.empty_create_news_content_error'));
    } else {
      postNews();
    }
  }

  return (
    <div
      onMouseEnter={() => setPostNewsIcon(true)} // Show blue icon on hover
      onMouseLeave={() => setPostNewsIcon(false)} // Show grey icon when not hovered
      onClick={handlePostNews} // Trigger the post news action
      className="pop__padded-content news--content create-news-options-padded-content post-news"
    >
      {/* Display post icon, changing color based on hover state */}
      <span className={postNewsIcon ? 'icon-post-news--blue' : 'icon-post-news--grey'} />
      <p>{I18n.t('news.options.create_news.post_news')}</p>
    </div>
  );
};

export default PostNews;

