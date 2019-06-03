import React from 'react';
import ReactDOM from 'react-dom';
import { Router } from 'react-router-dom';
import history from './util/history';
import routes from './util/routes.jsx';

import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import reducer from '../reducers';

import Nav from './nav/nav.jsx';

// The navbar is its own React element, independent of the
// main React Router-based component tree.
// `nav_root` is present throughout the app, via the Rails view layouts.
const navBar = document.getElementById('nav_root');
if (navBar) {
  ReactDOM.render((<Nav history={history} />), navBar);
}

// The main `react_root` is only present in some Rails views, corresponding
// to the routes above.
const reactRoot = document.getElementById('react_root');
if (reactRoot) {
  // This is basic, minimal state info extracted from the HTML,
  // used for initial rendering before React fetches all the specific
  // data it needs via API calls.
  const currentUserFromHtml = JSON.parse(reactRoot.getAttribute('data-current_user'));
  const admins = JSON.parse(reactRoot.getAttribute('data-admins'));
  const preloadedState = {
    courseCreator: {
      defaultCourseType: reactRoot.getAttribute('data-default-course-type'),
      courseStringPrefix: reactRoot.getAttribute('data-course-string-prefix'),
      useStartAndEndTimes: reactRoot.getAttribute('data-use-start-and-end-times') === 'true'
    },
    currentUserFromHtml,
    admins
  };

  // This is the Redux store.
  // It is accessed from container components via `connect()`.
  // Enable Redux DevTools browser extension.
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
  const store = createStore(
    reducer,
    preloadedState,
    composeEnhancers(applyMiddleware(thunk))
  );

  // Render the main React app
  ReactDOM.render((
    <Provider store={store} >
      <Router history={history}>
        {routes}
      </Router>
    </Provider>
  ), reactRoot);
}
