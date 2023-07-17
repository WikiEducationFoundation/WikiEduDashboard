import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

const Intro = ({ currentUser, returnToParam }) => {
  return (
    <div className="intro text-center">
      <h1>Hi {currentUser.real_name || currentUser.username}</h1>
      <p>We’re excited that you’re here!</p>
      <Link
        to={{
          pathname: '/onboarding/form',
          search: `?return_to=${returnToParam}`
        }}
        className="button border inverse-border"
      >
        Start <i className="icon icon-rt_arrow" />
      </Link>
    </div>
  );
};

Intro.propTypes = {
  currentUser: PropTypes.object,
  returnToParam: PropTypes.string,
};

export default Intro;
