import React, { useState } from 'react';

// Component to trigger the edit process of a news item
const EditNews = ({ setNewsIdToBeEdited, newsId }) => {
  const [editNews, setEditNews] = useState(false); // State to manage the icon hover effect

  return (
    <div
      onMouseEnter={() => setEditNews(true)} // Show blue icon on hover
      onMouseLeave={() => setEditNews(false)} // Revert to default icon on mouse leave
      onClick={() => setNewsIdToBeEdited(newsId)} // Trigger edit action
      className="pop__padded-content news--content edit-news-options-padded-content edit-news"
    >
      {/* Display edit icon, changing based on hover state */}
      <span className={editNews ? 'icon icon-pencil--blue' : 'icon icon-pencil'} />
      <p>{I18n.t('news.options.news_content.edit_news')}</p>
    </div>
  );
};

export default EditNews;
