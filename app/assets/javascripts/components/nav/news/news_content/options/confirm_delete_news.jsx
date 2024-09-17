import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { deleteSelectedNewsContent } from '@actions/news_action';
import { dispatchNotification } from '../../news_notification/notificationUtils';

// Component to confirm the deletion of a news item
const ConfirmDeleteNews = ({ newsId }) => {
  const [confirmingDelete, setConfirmingDelete] = useState(false); // State to manage the icon hover effect
  const dispatch = useDispatch();

  // Function to handle the confirmation of news deletion
  const confirmDeletion = async () => {
    dispatch(deleteSelectedNewsContent(newsId)); // Dispatch delete action
    dispatchNotification(dispatch, 'Success', I18n.t('news.notification.delete'));
  };

  return (
    <div
      onMouseEnter={() => setConfirmingDelete(true)} // Show blue icon on hover
      onMouseLeave={() => setConfirmingDelete(false)} // Show grey icon when not hovered
      onClick={confirmDeletion} // Trigger the delete action
      className="pop__padded-content news--content edit-news-options-padded-content confirm-delete"
    >
      {/* Display confirm icon, changing color based on hover state */}
      <span className={confirmingDelete ? 'icon-check icon-check--blue' : 'icon-check icon-check--grey'} />
      <p>{I18n.t('news.options.news_content.confirm_delete')}</p>
    </div>
  );
};

export default ConfirmDeleteNews;
