import React, { useState } from 'react';

// Component to discard the news creation process
const DiscardNewsCreation = ({ setCreateNews }) => {
  const [newsDiscardIcon, setNewsDiscardIcon] = useState(false); // State to manage the icon hover effect

  return (
    <div
      onMouseEnter={() => setNewsDiscardIcon(true)} // Show red icon on hover
      onMouseLeave={() => setNewsDiscardIcon(false)} // Show grey icon when not hovered
      onClick={() => setCreateNews(false)} // Discard the news creation process
      className="pop__padded-content news--content create-news-options-padded-content discard-news"
    >
      {/* Display discard icon, changing color based on hover state */}
      <span className={newsDiscardIcon ? 'icon-discard-news--red' : 'icon-discard-news--grey'} />
      <p>{I18n.t('news.options.create_news.discard_post')}</p> {/* Label for discard action */}
    </div>
  );
};

export default DiscardNewsCreation;
