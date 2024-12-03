import React from 'react';
import PropTypes from 'prop-types';
import { Navigate, NavLink, Route, Routes } from 'react-router-dom';

import RecentUploadsHandler from './recent_uploads_handler.jsx';

const RecentActivityHandler = () => (
  <div className="recent-activity__container">
    <nav>
      <div className="container">
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
        <Route path="recent-uploads" element={<RecentUploadsHandler />} />
        <Route path="*" element={<Navigate replace to="recent-uploads"/>}/>
      </Routes>
    </div>
  </div>
);

RecentActivityHandler.propTypes = {
  children: PropTypes.node
};

export default RecentActivityHandler;
