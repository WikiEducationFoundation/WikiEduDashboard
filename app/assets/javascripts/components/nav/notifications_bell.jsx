import React, { useEffect, useState } from 'react';
import request from '../../utils/request';

const NotificationsBell = () => {
  const [hasOpenTickets, setHasOpenTickets] = useState(false);
  const [hasRequestedAccounts, setHasRequestedAccounts] = useState(false);

  useEffect(() => {
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
              <span id="notification-message" className="screen-reader">You have new notifications.</span>
            </span>
          )
          : (
            <span id="notification-message" className="screen-reader">You have no new notifications.</span>
          )
      }
    </li>
  );
};

export default (NotificationsBell);
