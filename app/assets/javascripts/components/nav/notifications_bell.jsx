import React, { useEffect, useState } from 'react';
import request from '../../utils/request';

// Routes where notification data is not contextually relevant
export const SKIP_NOTIFICATION_ROUTES = ['/survey', '/faq', '/training', '/onboarding'];

// Helper function to check if current route should skip notifications
export const shouldSkipNotificationFetch = (pathname) => {
  return SKIP_NOTIFICATION_ROUTES.some(route => pathname.startsWith(route));
};

// Cache configuration
const CACHE_KEYS = {
  REQUESTED_ACCOUNTS: 'notifications_requested_accounts',
  OPEN_TICKETS: 'notifications_open_tickets',
  TIMESTAMP: 'notifications_cache_timestamp'
};
const CACHE_TTL_MS = 30000; // 30 seconds

// Helper: Check if cache is still valid
export const isCacheValid = (storage = sessionStorage) => {
  const timestamp = storage.getItem(CACHE_KEYS.TIMESTAMP);
  if (!timestamp) return false;
  return Date.now() - parseInt(timestamp) < CACHE_TTL_MS;
};

// Helper: Get cached value
export const getCached = (key, storage = sessionStorage) => {
  if (!isCacheValid(storage)) return null;
  const value = storage.getItem(key);
  if (value === null) return null;
  return value === 'true';
};

// Helper: Set cache with timestamp
export const setCache = (key, value, storage = sessionStorage) => {
  storage.setItem(key, String(value));
  storage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));
};

// Export for testing
export { CACHE_KEYS, CACHE_TTL_MS };

const NotificationsBell = () => {
  const [hasOpenTickets, setHasOpenTickets] = useState(false);
  const [hasRequestedAccounts, setHasRequestedAccounts] = useState(false);

  useEffect(() => {
    // Skip fetching notifications on irrelevant routes
    if (shouldSkipNotificationFetch(window.location.pathname)) {
      return;
    }

    // Check cache first and use cached values if valid
    if (isCacheValid()) {
      const cachedRequestedAccounts = getCached(CACHE_KEYS.REQUESTED_ACCOUNTS);
      const cachedOpenTickets = getCached(CACHE_KEYS.OPEN_TICKETS);

      if (cachedRequestedAccounts !== null) {
        setHasRequestedAccounts(cachedRequestedAccounts);
      }
      if (cachedOpenTickets !== null) {
        setHasOpenTickets(cachedOpenTickets);
      }
      // Skip API calls since cache is still valid
      return;
    }

    // Fetch fresh data and update cache
    const main = document.getElementById('main');
    const userId = main ? main.dataset.userId : null;
    if (Features.wikiEd && userId) {
      request(`/td/open_tickets?owner_id=${userId}`)
        .then(res => res.json())
        .then(({ open_tickets }) => {
          setHasOpenTickets(open_tickets);
          setCache(CACHE_KEYS.OPEN_TICKETS, open_tickets);
        })
        .catch(err => err);
    }

    request('/requested_accounts.json')
      .then(res => res.json())
      .then(({ requested_accounts }) => {
        setHasRequestedAccounts(requested_accounts);
        setCache(CACHE_KEYS.REQUESTED_ACCOUNTS, requested_accounts);
      })
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
