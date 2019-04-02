import React from 'react';
import fetch from 'cross-fetch';

export default class NotificationsBell extends React.Component {
  constructor() {
    super();
    this.state = {};
  }

  componentDidMount() {
    fetch('/requested_accounts.json')
      .then(res => res.json())
      .then(({ requested_accounts }) => this.setState({ requested_accounts }))
      .catch(err => err); // If this errors, we're going to ignore it
  }

  render() {
    return (
      <li aria-describedby="notification-message" className="notifications">
        <a href="/requested_accounts" className="icon icon-notifications_bell"/>
        {
          this.state.requested_accounts
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
