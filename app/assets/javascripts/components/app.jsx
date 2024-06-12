import React from 'react';
import Nav from './nav/nav.jsx';
import { render as renderMain } from './Main';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import store from './util/create_store';

// Render the Nav component with Redux store
const navBar = document.getElementById('nav_root');
if (navBar) {
  const navRoot = createRoot(navBar);
  navRoot.render(
    <Provider store={store}>
      <Nav />
    </Provider>
  );
}

// Render the Main component with the same Redux store and React Router
const reactRoot = document.getElementById('react_root');
if (reactRoot) {
  renderMain(
    reactRoot,
    store
  );
}
