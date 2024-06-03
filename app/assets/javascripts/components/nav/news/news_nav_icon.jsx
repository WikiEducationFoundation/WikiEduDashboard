import React, { useState, useEffect } from 'react';
import API from '../../../utils/api';
import { Cookies } from 'react-cookie-consent';

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

    Cookies.set(`lastFetchTimestamp_${newsType}`, currentTimestamp, { expires: expires });
  };

  useEffect(() => {
  const fetchData = async () => {
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
      // eslint-disable-next-line no-console
      console.error('Error fetching news:', error);
    }
  };

  // Call the asynchronous function
  fetchData();
  }, []);

  return (
    <li aria-describedby="notification-message" className="notifications tooltip-trigger" onClick={onClickNewsIcon}>
      <a className="icon icon-notifications_news">
        {/* Conditionally render the badge */}
        {notificationCount > 0 && (
          <div className="icon-notification_news--badge">
            {notificationCount}
          </div>
        )}
      </a>
      <div className="tooltip tooltip--news tooltip--nav">
        <p>
          {I18n.t('news.nav_tooltip')}
        </p>
      </div>
    </li>
  );
};

export default NewsNavIcon;
