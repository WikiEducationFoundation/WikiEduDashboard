import React from 'react';
import PropTypes from 'prop-types';
import { NavLink, Redirect, Route, Switch } from 'react-router-dom';

import DidYouKnowHandler from './did_you_know_handler.jsx';
import PlagiarismHandler from './plagiarism_handler.jsx';
import RecentEditsHandler from './recent_edits_handler.jsx';
import RecentUploadsHandler from './recent_uploads_handler.jsx';

const RecentActivityHandler = () => (
  <div className="recent-activity__container">
    <nav>
      <div className="container">
        <div className="nav__item" id="dyk-link">
          <p>
            <NavLink to="/recent-activity/dyk" activeClassName="active">
              {I18n.t('recent_activity.did_you_know_eligible')}
            </NavLink>
          </p>
        </div>

        <div className="nav__item" id="plagiarism-link">
          <p>
            <NavLink to="/recent-activity/plagiarism" activeClassName="active">
              {I18n.t('recent_activity.possible_plagiarism')}
            </NavLink>
          </p>
        </div>

        <div className="nav__item" id="recent-edits-link">
          <p>
            <NavLink to="/recent-activity/recent-edits" activeClassName="active">
              {I18n.t('recent_activity.recent_edits')}
            </NavLink>
          </p>
        </div>

        <div className="nav__item" id="recent-uploads-link">
          <p>
            <NavLink to="/recent-activity/recent-uploads" activeClassName="active">
              {I18n.t('recent_activity.recent_uploads')}
            </NavLink>
          </p>
        </div>
      </div>
    </nav>

    <div className="container">
      <Switch>
        <Route exact path="/recent-activity/dyk" component={DidYouKnowHandler} />
        <Route exact path="/recent-activity/plagiarism" component={PlagiarismHandler} />
        <Route exact path="/recent-activity/recent-edits" component={RecentEditsHandler} />
        <Route exact path="/recent-activity/recent-uploads" component={RecentUploadsHandler} />
        <Redirect to="/recent-activity/dyk" />
      </Switch>
    </div>
  </div>
);

RecentActivityHandler.propTypes = {
  children: PropTypes.node
};

export default RecentActivityHandler;
