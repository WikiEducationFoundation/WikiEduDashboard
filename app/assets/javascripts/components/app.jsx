import React from 'react';
import Nav from './nav/nav.jsx';
import { render as renderMain } from './Main';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import store from './util/create_store';

// The navbar is its own React element, independent of the
// main React Router-based component tree.
// `nav_root` is present throughout the app, via the Rails view layouts.
const navBar = document.getElementById('nav_root');

if (navBar) {
  const navRoot = createRoot(navBar); // createRoot(container!) if you use TypeScript
  // Render the Nav component with Redux store
  navRoot.render(
    <Provider store={store}>
      <Nav />
    </Provider>
  );
}

const reactRoot = document.getElementById('react_root');

if (reactRoot) {
  // Render the Main component with the same Redux store and React Router
  renderMain(
    reactRoot,
    store
  );
}
