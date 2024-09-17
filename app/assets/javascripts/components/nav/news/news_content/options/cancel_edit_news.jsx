import React, { useState } from 'react';

// Component to cancel the news edit process
const CancelEditNews = ({ cancelNewsIdToBeEdited }) => {
  const [cancelEdit, setCancelEdit] = useState(false); // State to manage the icon hover effect

  return (
    <div
      onMouseEnter={() => setCancelEdit(true)} // Show red icon on hover
      onMouseLeave={() => setCancelEdit(false)} // Show grey icon when not hovered
      onClick={cancelNewsIdToBeEdited} // Cancel the edit action
      className="pop__padded-content news--content edit-news-options-padded-content cancel-edit"
    >
      {/* Display cancel icon, changing color based on hover state */}
      <span className={cancelEdit ? 'icon-cancel icon-cancel--red' : 'icon-cancel icon-cancel--grey'} />
      <p>{I18n.t('news.options.news_content.cancel_edit')}</p>
    </div>
  );
};

export default CancelEditNews;
