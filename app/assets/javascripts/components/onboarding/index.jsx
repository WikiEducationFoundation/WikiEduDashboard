import React from 'react';
import PropTypes from 'prop-types';
import { Route, Switch } from 'react-router-dom';
import TransitionGroup from '../common/css_transition_group';
import Intro from './intro.jsx';
import Form from './form.jsx';
import Supplementary from './supplementary.jsx';
import Permissions from './permissions.jsx';
import Finished from './finished.jsx';

import Notifications from '../common/notifications.jsx';

const getReturnToParam = function () {
  const returnTo = window.location.search.match(/return_to=([^&]*)/);
  return (returnTo && returnTo[1]) || '/';
};

const getCurrentUser = () => $('#react_root').data('current_user');

const setProps = ({ pathname }) => ({
  pathname, returnToParam: getReturnToParam(), currentUser: getCurrentUser()
});

// Router root
const Root = ({ location }) => {
  const props = setProps(location);
  return (
    <div className="container">
      <Notifications />
      <TransitionGroup
        classNames="fade"
        component="div"
        timeout={250}
      >
        <Switch key={location.key} location={location}>
          <Route exact path="/onboarding" render={() => <Intro {...props} />} />
          <Route exact path="/onboarding/form" render={() => <Form {...props} />} />
          <Route exact path="/onboarding/supplementary" render={() => <Supplementary {...props} />} />
          <Route exact path="/onboarding/permissions" render={() => <Permissions {...props} />} />
          <Route exact path="/onboarding/finish" render={() => <Finished {...props} />} />
        </Switch>
      </TransitionGroup>
    </div>
  );
};

Root.propTypes = {
  children: PropTypes.object,
  location: PropTypes.object
};

export default Root;
