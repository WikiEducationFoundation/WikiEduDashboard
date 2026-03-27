import React from 'react';
import { NavLink } from 'react-router-dom';

export const SubNavigation = ({ heading, links }) => {
  const navLinks = links.map(({ href, text }, index) => {
    return (
      <li key={index}>
        <NavLink to={href} className={({ isActive }) => `${isActive ? 'active' : ''} button`}>
          {text}
        </NavLink>
      </li>
    );
  });

  return (
    <div className="section-header">
      <nav className="sub-navigation" aria-label={heading || I18n.t('courses.sub_navigation')}>
        {
          heading && <h3>{heading}</h3>
        }
        <ul>
          { navLinks }
        </ul>
      </nav>
    </div>
  );
};

SubNavigation.propTypes = {
  heading: PropTypes.string,
  links: PropTypes.arrayOf(PropTypes.shape({
    href: PropTypes.string.isRequired,
    text: PropTypes.string.isRequired
  })).isRequired
};

export default SubNavigation;
