import React from 'react';
import request from '../../utils/request';

export default class NotificationsBell extends React.Component {
  constructor() {
    super();
    this.state = { open_tickets: false, requested_accounts: false };
  }

  componentDidMount() {
    const main = document.getElementById('main');
    const userId = main ? main.dataset.userId : null;

    if (Features.wikiEd && userId) {
      request(`/td/open_tickets?owner_id=${userId}`)
        .then(res => res.json())
        .then(({ open_tickets }) => this.setState({ open_tickets }))
        .catch(err => err);
    }

    request('/requested_accounts.json')
      .then(res => res.json())
      .then(({ requested_accounts }) => this.setState({ requested_accounts }))
      .catch(err => err); // If this errors, we're going to ignore it
  }

  render() {
    const path = Features.wikiEd ? '/admin' : '/requested_accounts';
    return (
      <li aria-describedby="notification-message" className="notifications">
        <a href={path} className="icon icon-notifications_bell"/>
        {
          (this.state.requested_accounts || this.state.open_tickets)
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
  }
}
