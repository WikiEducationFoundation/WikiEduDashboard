import React, { useState } from 'react';

// Component to trigger the deletion process of a news item
const DeleteNews = ({ setConfirmDeleteNewsId, newsId }) => {
  const [deleteNews, setDeleteNews] = useState(false); // State to manage the icon hover effect

  return (
    <div
      onMouseEnter={() => setDeleteNews(true)} // Show hover icon on mouse enter
      onMouseLeave={() => setDeleteNews(false)} // Revert to default icon on mouse leave
      onClick={() => setConfirmDeleteNewsId(newsId)} // Trigger delete confirmation
      className="pop__padded-content news--content edit-news-options-padded-content delete-news"
    >
      {/* Display delete icon, changing based on hover state */}
      <span className={deleteNews ? 'icon icon-trash_can-hover' : 'icon icon-trash_can'} />
      <p>{I18n.t('news.options.news_content.delete_news')}</p>
    </div>
  );
};

export default DeleteNews;
