import React from 'react';
import { Link } from 'react-router';

const RecentActivityHandler = React.createClass({
  displayName: 'RecentActivityHandler',

  propTypes: {
    children: React.PropTypes.node
  },

  render() {
    return (
      <div className="container recent-activity__container">
        <nav className="container">
          <div className="nav__item" id="dyk-link">
            <p><Link to="/recent-activity">{I18n.t('recent_activity.did_you_know_eligible')}</Link></p>
          </div>
          <div className="nav__item" id="plagiarism-link">
            <p><Link to="/recent-activity/plagiarism">{I18n.t('recent_activity.possible_plagiarism')}</Link></p>
          </div>
          <div className="nav__item" id="recent-edits-link">
            <p><Link to="/recent-activity/recent-edits">{I18n.t('recent_activity.recent_edits')}</Link></p>
          </div>
        </nav>
        {this.props.children}
      </div>
    );
  }
});

export default RecentActivityHandler;
