import React from 'react';
import { render } from '@testing-library/react';
import { Provider } from 'react-redux';
import { configureStore } from '@reduxjs/toolkit';
import reducer from '../app/assets/javascripts/reducers/index';
import { apiSlice } from '../app/assets/javascripts/components/util/apiSlice';

// Include all reducers needed for tests
const createTestStore = () => {
  return configureStore({
    reducer,
    middleware: getDefaultMiddleware =>
      getDefaultMiddleware({ serializableCheck: false }).concat(apiSlice.middleware),
  });
};

// Utility function for rendering components with Redux store
export function renderWithProviders(ui, { preloadedState, store = createTestStore(), ...renderOptions } = {}) {
  function Wrapper({ children }) {
    return <Provider store={store}>{children}</Provider>;
  }

  return {
    store, // Expose the store for debugging or further actions
    ...render(ui, { wrapper: Wrapper, ...renderOptions }),
  };
}
