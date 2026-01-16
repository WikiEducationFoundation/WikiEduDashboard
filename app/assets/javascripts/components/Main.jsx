import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import Routes from './util/routes.jsx';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import { ToastContainer } from 'react-toastify';

const Main = ({ store }) => {
  return (
    <Provider store={store}>
      <BrowserRouter>
        <Routes />
        <ToastContainer />
      </BrowserRouter>
    </Provider>
  );
};

export const render = (container, store) => {
  const root = createRoot(container);
  root.render(<Main store={store} />);
};
