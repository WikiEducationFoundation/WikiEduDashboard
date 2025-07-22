import React from 'react';
import PropTypes from 'prop-types';
import { Route, Routes, useLocation } from 'react-router-dom';
import TransitionGroup from '../common/css_transition_group';
import Intro from './intro.jsx';
import Form from './form.jsx';
import Supplementary from './supplementary.jsx';
import Permissions from './permissions.jsx';
import Finished from './finished.jsx';

import Notifications from '../common/notifications.jsx';
import { useSelector } from 'react-redux';

const getReturnToParam = function () {
  const returnTo = window.location.search.match(/return_to=([^&]*)/);
  return (returnTo && returnTo[1]) || '/';
};

const setProps = ({ pathname }) => ({
  pathname, returnToParam: getReturnToParam()
});

// Router root
const Root = () => {
  const location = useLocation();
  const currentUser = useSelector(state => state.currentUserFromHtml);
  const props = { ...setProps(location), currentUser };
  return (
    <div className="container">
      <Notifications />
      <TransitionGroup
        classNames="fade"
        component="div"
        timeout={250}
      >
        <Routes>
          <Route path="/" element={<Intro {...props} />} />
          <Route path="form" element={<Form {...props} />} />
          <Route path="supplementary" element={<Supplementary {...props} />} />
          <Route path="permissions" element={<Permissions {...props} />} />
          <Route path="finish" element={<Finished {...props} />} />
        </Routes>
      </TransitionGroup>
    </div>
  );
};

Root.propTypes = {
  children: PropTypes.object,
};

export default Root;
