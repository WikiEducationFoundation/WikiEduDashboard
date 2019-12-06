import React from 'react';
import { NavLink } from 'react-router-dom';

export const SubNavigation = ({ links }) => {
  const navLinks = links.map(({ href, text }, index) => {
    return (
      <li key={index}>
        <NavLink to={href} activeClassName="active" className="button">
          {text}
        </NavLink>
      </li>
    );
  });

  return (
    <nav className="sub-navigation">
      <ul>
        { navLinks }
      </ul>
    </nav>
  );
};

export default SubNavigation;
