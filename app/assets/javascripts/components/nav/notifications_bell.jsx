import React, { useEffect, useState } from 'react';
import request from '../../utils/request';

// Routes where notification data is not contextually relevant
export const SKIP_NOTIFICATION_ROUTES = ['/survey', '/faq', '/training', '/onboarding'];

// Helper function to check if current route should skip notifications
export const shouldSkipNotificationFetch = (pathname) => {
  return SKIP_NOTIFICATION_ROUTES.some(route => pathname.startsWith(route));
};

const NotificationsBell = () => {
  const [hasOpenTickets, setHasOpenTickets] = useState(false);
  const [hasRequestedAccounts, setHasRequestedAccounts] = useState(false);

  useEffect(() => {
    // Skip fetching notifications on irrelevant routes
    if (shouldSkipNotificationFetch(window.location.pathname)) {
      return;
    }

    const main = document.getElementById('main');
    const userId = main ? main.dataset.userId : null;
    if (Features.wikiEd && userId) {
      request(`/td/open_tickets?owner_id=${userId}`)
        .then(res => res.json())
        .then(({ open_tickets }) => setHasOpenTickets(open_tickets))
        .catch(err => err);
    }

    request('/requested_accounts.json')
      .then(res => res.json())
      .then(({ requested_accounts }) => setHasRequestedAccounts(requested_accounts))
      .catch(err => err); // If this errors, we're going to ignore it
  }, []);

  const path = Features.wikiEd ? '/admin' : '/requested_accounts';
  return (
    <li aria-describedby="notification-message" className="notifications">
      <a href={path} className="icon icon-notifications_bell" />
      {
        (hasRequestedAccounts || hasOpenTickets)
          ? (
            <span className="bubble red">
              <span id="notification-message" className="screen-reader">{I18n.t('notifications.new_notifications')}</span>
            </span>
          )
          : (
            <span id="notification-message" className="screen-reader">{I18n.t('notifications.no_notifications')}</span>
          )
      }
    </li>
  );
};

export default (NotificationsBell);
