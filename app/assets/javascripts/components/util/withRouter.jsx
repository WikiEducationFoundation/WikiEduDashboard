// See https://reactrouter.com/docs/en/v6/faq#what-happened-to-withrouter-i-need-it
// This wrapper component only exists to ensure a relatively seemless migration to React Router v6
// which only uses hooks to do Route management, which can't be used inside of class based components

// In the future, new components should be written as functional ones to avoid the use of this
// wrapper. If you need to add some route management to some existing class components, you
// will have to use this, unless you convert the component to a functional one first

// Once all class based components which use routing have been converted to functional ones,
// this wrapper can be safely deleted.

import React from 'react';
import {
  useLocation,
  useNavigate,
  useParams,
} from 'react-router-dom';

function withRouter(Component) {
  function ComponentWithRouterProp(props) {
    const location = useLocation();
    const navigate = useNavigate();
    const params = useParams();
    return (
      <Component
        {...props}
        router={{ location, navigate, params }}
      />
    );
  }

  return ComponentWithRouterProp;
}

export default withRouter;
