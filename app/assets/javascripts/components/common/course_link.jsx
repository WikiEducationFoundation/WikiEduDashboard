import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router';

const CourseLink = ({ to, className, onClick, children }) => (
  <Link
    to={to}
    className={className}
    onClick={onClick}
  >
    {children}
  </Link>
);

CourseLink.propTypes = {
  to: PropTypes.string,
  className: PropTypes.string,
  onClick: PropTypes.func,
  children: PropTypes.node
};

export default CourseLink;
