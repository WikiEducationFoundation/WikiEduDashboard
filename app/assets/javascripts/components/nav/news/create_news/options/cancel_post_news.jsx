import React, { useState } from 'react';

// Component to cancel the news posting process
const CancelPostNews = ({ setConfirmPost }) => {
  const [cancelPostIcon, setCancelPostIcon] = useState(false); // State to manage the icon hover effect

  // Function to cancel the news post confirmation
  const cancelNewsPost = () => {
    setConfirmPost(false); // Set the confirm post state to false
  };

  return (
    <div
      onMouseEnter={() => setCancelPostIcon(true)} // Show red icon on hover
      onMouseLeave={() => setCancelPostIcon(false)} // Show grey icon when not hovered
      onClick={cancelNewsPost} // Call function to cancel news post confirmation
      className="pop__padded-content news--content edit-news-options-padded-content cancel-post"
    >
      {/* Display cancel icon, changing color based on hover state */}
      <span className={cancelPostIcon ? 'icon-cancel icon-cancel--red' : 'icon-cancel icon-cancel--grey'} />
      <p>{I18n.t('news.options.create_news.cancel_post')}</p> {/* Label for cancel action */}
    </div>
  );
};

export default CancelPostNews;
