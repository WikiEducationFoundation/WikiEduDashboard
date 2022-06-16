import React from 'react';
import ReactDOM from 'react-dom';
import Nav from './nav/nav.jsx';
import { render } from './Main';

// The navbar is its own React element, independent of the
// main React Router-based component tree.
// `nav_root` is present throughout the app, via the Rails view layouts.
const navBar = document.getElementById('nav_root');
if (navBar) {
  ReactDOM.render((<Nav/>), navBar);
}

const reactRoot = document.getElementById('react_root');

if (reactRoot) {
  render(reactRoot);
}
