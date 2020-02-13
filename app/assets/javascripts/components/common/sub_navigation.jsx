import React from 'react';
import { NavLink } from 'react-router-dom';

export const SubNavigation = ({ heading, links }) => {
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
    <div className="section-header">
      <nav className="sub-navigation">
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

export default SubNavigation;
