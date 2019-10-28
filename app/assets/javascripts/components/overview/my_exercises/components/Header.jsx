import React from 'react';
import PropTypes from 'prop-types';
import { NavLink } from 'react-router-dom';

export const Header = ({ completed = false, course, remaining = [], text }) => (
  <header className="header">
    <h3 className={completed ? 'completed' : ''}>
      { text }
      {
        remaining.length
        ? <small>{remaining.length} additional exercises remaining.</small>
        : null
      }
    </h3>
    <NavLink exact to={`/courses/${course.slug}/resources`} className="resources-link">
      View all exercises
    </NavLink>
  </header>
);

Header.propTypes = {
  course: PropTypes.shape({
    slug: PropTypes.string.isRequired
  }).isRequired,
  remaining: PropTypes.array,
  text: PropTypes.string.isRequired
};

export default Header;
