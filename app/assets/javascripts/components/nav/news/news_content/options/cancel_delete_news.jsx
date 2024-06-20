import React, { useState } from 'react';

// Component to cancel the news deletion process
const CancelDeleteNews = ({ setConfirmDeleteNews }) => {
  const [cancelDelete, setCancelDelete] = useState(false); // State to manage the icon hover effect

  return (
    <div
      onMouseEnter={() => setCancelDelete(true)} // Show red icon on hover
      onMouseLeave={() => setCancelDelete(false)} // Show grey icon when not hovered
      onClick={() => setConfirmDeleteNews(null)} // Cancel the delete action
      className="pop__padded-content news--content edit-news-options-padded-content cancel-delete"
    >
      {/* Display cancel icon, changing color based on hover state */}
      <span className={cancelDelete ? 'icon-cancel icon-cancel--red' : 'icon-cancel icon-cancel--grey'} />
      <p>{I18n.t('news.options.news_content.cancel_delete')}</p>
    </div>
  );
};

export default CancelDeleteNews;
