import React from 'react';
import PropTypes from 'prop-types';

// components
import Tooltip from './Tooltip';

export const Header = ({ message, sub, title }) => (
  <h4 className="mb1 mt2">
    { title }&nbsp;
    { sub && <Tooltip message={message} text={sub} /> }
  </h4>
);

Header.propTypes = {
  // props
  message: PropTypes.string,
  sub: PropTypes.string,
  title: PropTypes.string.isRequired,
};

export default Header;
