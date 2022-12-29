import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import Routes from './util/routes.jsx';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import store from './util/create_store';

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
    ReactDOM.render(
      <Main/>,
      reactRoot
    );
};
