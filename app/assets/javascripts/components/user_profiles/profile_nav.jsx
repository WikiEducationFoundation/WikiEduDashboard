import React from 'react';
import PropTypes from 'prop-types';
import { NavLink } from 'react-router-dom';

const ProfileNav = ({ username }) => {
  const encodedUsername = encodeURIComponent(username);
  const base = `/users/${encodedUsername}`;

  return (
    <nav className="profile-nav">
      <div className="container">
        <ul className="top-nav__main-links">
          <li>
            <NavLink
              to={base}
              end
              className={({ isActive }) => (isActive ? 'active' : '')}
            >
              {I18n.t('users.contribution_statistics')}
            </NavLink>
          </li>
          <li>
            <NavLink
              to={`${base}/course-details`}
              className={({ isActive }) => (isActive ? 'active' : '')}
            >
              {I18n.t('courses.course_details')}
            </NavLink>
          </li>
          <li>
            <NavLink
              to={`${base}/uploads`}
              className={({ isActive }) => (isActive ? 'active' : '')}
            >
              {I18n.t('courses.user_recent_uploads')}
            </NavLink>
          </li>
          <li>
            <NavLink
              to={`${base}/training`}
              className={({ isActive }) => (isActive ? 'active' : '')}
            >
              {I18n.t('users.user_training_status')}
            </NavLink>
          </li>
        </ul>
      </div>
    </nav>
  );
};

ProfileNav.propTypes = {
  username: PropTypes.string.isRequired
};

export default ProfileNav;
