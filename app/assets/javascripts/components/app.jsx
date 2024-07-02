import React from 'react';
import Nav from './nav/nav.jsx';
import { render } from './Main';
import { createRoot } from 'react-dom/client';

// The navbar is its own React element, independent of the
// main React Router-based component tree.
// `nav_root` is present throughout the app, via the Rails view layouts.
const navBar = document.getElementById('nav_root');
const root = createRoot(navBar); // createRoot(container!) if you use TypeScript

if (navBar) {
  root.render((<Nav />));
}

const reactRoot = document.getElementById('react_root');

if (reactRoot) {
  render(reactRoot);
}
