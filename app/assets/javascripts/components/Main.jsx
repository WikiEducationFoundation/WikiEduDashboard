import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import Routes from './util/routes.jsx';
import { Provider } from 'react-redux';
import store from './util/create_store';
import { createRoot } from 'react-dom/client';

const Main = () => {
  return (
    <Provider store={store} >
      <BrowserRouter>
        <Routes />
      </BrowserRouter>
    </Provider>
  );
};
export const render = (reactRoot) => {
  const root = createRoot(reactRoot);
  root.render(
    <Main />,
  );
};
