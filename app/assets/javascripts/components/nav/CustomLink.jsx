// Replacement for non-custom Link component. The react Link component doesn't highlight the active link if it is not handled by react router
// CustomLink is used to provide that functioning.
import React from 'react';
import PropTypes from 'prop-types';

const CustomLink = ({ clickedElement, to, target, name }) => {
  const isActive = () => {
    const path = location.pathname.split('/')[1];
    return path === clickedElement;
  };
  return <a href={to} className={isActive() ? 'active' : ''} target={target}> {name} </a>;
};

CustomLink.propTypes = {
  to: PropTypes.string,
  name: PropTypes.string,
  clickedElement: PropTypes.string,
  target: PropTypes.string
};

export default CustomLink;
