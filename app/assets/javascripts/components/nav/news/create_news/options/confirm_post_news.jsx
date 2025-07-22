import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { createNewsContent } from '@actions/news_action';
import { dispatchNotification } from '../../news_notification/notificationUtils';

const ConfirmPostNews = ({ setConfirmPost, setDisableDropdown, setCreateNews }) => {
  const [confirmPostIcon, setConfirmPostIcon] = useState(false);
  const dispatch = useDispatch();

  // Function to handle the confirmation of the news post
  const confirmPostNews = async () => {
    setConfirmPost(false);
    setDisableDropdown(true);

    try {
      const status = await dispatch(createNewsContent(null, true));
      if (status?.id) {
        setCreateNews(false);
        dispatchNotification(dispatch, 'Success', I18n.t('news.notification.create_news'));
      }
    } catch (error) {
      dispatchNotification(dispatch, 'Error', I18n.t('news.notification.create_news_error'));
    }
  };

  return (
    <div
      onMouseEnter={() => setConfirmPostIcon(true)}
      onMouseLeave={() => setConfirmPostIcon(false)}
      onClick={confirmPostNews}
      className="pop__padded-content news--content edit-news-options-padded-content confirm-post"
    >
      <span className={confirmPostIcon ? 'icon-check icon-check--blue' : 'icon-check icon-check--grey'} />
      <p>{I18n.t('news.options.create_news.confirm_post')}</p>
    </div>
  );
};

export default ConfirmPostNews;
