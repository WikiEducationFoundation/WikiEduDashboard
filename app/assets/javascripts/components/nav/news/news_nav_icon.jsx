import React, { useState, useEffect } from 'react';
import API from '../../../utils/api';
import { Cookies } from 'react-cookie-consent';
import logErrorMessage from '~/app/assets/javascripts/utils/log_error_message';

const NewsNavIcon = ({ setIsOpen }) => {
  const [notificationCount, setNotificationCount] = useState(0);
  const newsType = Features.wikiEd ? 'Wiki Education News' : 'Programs & Events Dashboard News';

  const onClickNewsIcon = () => {
    setIsOpen(x => !x);
    setNotificationCount(0);
    // Set the current timestamp as a cookie when the user fetches news
    const currentTimestamp = Date.now();

    // Set the expiration date to 10 years from now
    const expires = new Date();
    expires.setFullYear(expires.getFullYear() + 10);

    Cookies.set(`lastFetchTimestamp_${newsType}`, currentTimestamp, { expires });
  };

  useEffect(() => {
    const fetchNewsData = async () => {
      try {
        const newsContentList = await API.fetchNews(newsType);

        // Retrieve the last fetch timestamp from the cookie
        const userLastFetchTimestamp = Cookies.get(`lastFetchTimestamp_${newsType}`);

        // Check if the cookie value is a valid number
        const parsedTimestamp = isFinite(userLastFetchTimestamp) ? parseInt(userLastFetchTimestamp) : 0;

        // Calculate the count of new news items
        const newNewsCount = newsContentList.filter(newsItem => new Date(newsItem.updated_at) > new Date(parsedTimestamp)).length;

        // Update the notification count state
        setNotificationCount(newNewsCount);
      } catch (error) {
        logErrorMessage('Error fetching news:', error);
      }
    };

    fetchNewsData();
  }, []);

  return (
    <li aria-describedby="notification-message" className="notifications tooltip-trigger">
      <button type="button" className="icon icon-notifications_news" onClick={onClickNewsIcon} aria-label={I18n.t('notifications.aria_label.bell')}>
        {/* Conditionally render the badge */}
        {notificationCount > 0 && (
          <div className="icon-notification_news--badge">
            {notificationCount}
          </div>
        )}
      </button>
      <div className="tooltip tooltip--news tooltip--nav">
        <p>
          {I18n.t('news.nav_tooltip')}
        </p>
      </div>
    </li>
  );
};

export default NewsNavIcon;
