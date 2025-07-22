import React from 'react';
import DiscardNewsCreation from './options/discard_news_creation';
import CancelPostNews from './options/cancel_post_news';
import PostNews from './options/post_news';
import ConfirmPostNews from './options/confirm_post_news';

// Component to display options for creating news
const CreateNewsDropdown = ({ setCreateNews, postNews, confirmPost, setConfirmPost, setDisableDropdown }) => {
  let firstOptions;
  let secondOptions;

  // Determine which set of options to display based on confirmation state
  switch (true) {
    case confirmPost:
      // If confirming post, show confirm and cancel options
      firstOptions = (<ConfirmPostNews setConfirmPost={setConfirmPost} setDisableDropdown={setDisableDropdown} setCreateNews={setCreateNews} />);
      secondOptions = (<CancelPostNews setConfirmPost={setConfirmPost} />);
      break;
    default:
      // If not confirming, show post and discard options
      firstOptions = (<PostNews postNews={postNews} />);
      secondOptions = (<DiscardNewsCreation setCreateNews={setCreateNews} />);
  }

  return (
    <div
      onClick={(e) => { e.stopPropagation(); }} // Prevent click event from propagating
      className="pop__container news-dropdown-options"
    >
      <div className="pop pop--news open">
        <div className="news-dropdown-options-display">
          {firstOptions} {/* Render the first set of options */}
          <hr className="news-hr" /> {/* Horizontal rule separator */}
          {secondOptions} {/* Render the second set of options */}
        </div>
      </div>
    </div>
  );
};

export default CreateNewsDropdown;
