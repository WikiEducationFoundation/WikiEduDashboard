import React from 'react';
import PropTypes from 'prop-types';
import { Navigate, NavLink, Route, Routes } from 'react-router-dom';

import DidYouKnowHandler from './did_you_know_handler.jsx';
import RecentUploadsHandler from './recent_uploads_handler.jsx';

const RecentActivityHandler = () => (
  <div className="recent-activity__container">
    <nav>
      <div className="container">
        <div className="nav__item" id="dyk-link">
          <p>
            <NavLink
              to="/recent-activity/dyk" className={({ isActive }) => (isActive ? 'active' : '')}
            >
              {I18n.t('recent_activity.did_you_know_eligible')}
            </NavLink>
          </p>
        </div>
        <div className="nav__item" id="recent-uploads-link">
          <p>
            <NavLink to="/recent-activity/recent-uploads" className={({ isActive }) => (isActive ? 'active' : '')}>
              {I18n.t('recent_activity.recent_uploads')}
            </NavLink>
          </p>
        </div>
      </div>
    </nav>

    <div className="container">
      <Routes>
        <Route path="dyk" element={<DidYouKnowHandler />} />
        <Route path="recent-uploads" element={<RecentUploadsHandler />} />
        <Route path="*" element={<Navigate replace to="dyk"/>}/>
      </Routes>
    </div>
  </div>
);

RecentActivityHandler.propTypes = {
  children: PropTypes.node
};

export default RecentActivityHandler;
