import React from 'react';
import PropTypes from 'prop-types';
import TransitionGroup from 'react-transition-group/CSSTransitionGroup';

import Notifications from '../common/notifications.jsx';

const getReturnToParam = function () {
  const returnTo = window.location.search.match(/return_to=([^&]*)/);
  return (returnTo && returnTo[1]) || '/';
};

const getCurrentUser = () => $('#react_root').data('current_user');

// Router root
const Root = ({ children, location }) => (
  <div className="container">
    <Notifications />
    <TransitionGroup
      transitionName="fade"
      component="div"
      transitionEnterTimeout={250}
      transitionLeaveTimeout={250}
    >
      {React.cloneElement(children, {
        key: location.pathname,
        returnToParam: getReturnToParam(),
        currentUser: getCurrentUser()
      })}
    </TransitionGroup>
  </div>
);

Root.propTypes = {
  children: PropTypes.object,
  location: PropTypes.object
};

export default Root;
