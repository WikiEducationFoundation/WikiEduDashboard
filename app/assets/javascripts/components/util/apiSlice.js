// Import the RTK Query methods from the React-specific entry point
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import Rails from '@rails/ujs';

// Define our single API slice object
export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({
    prepareHeaders: (headers) => {
      // Add CSRF token for all requests through RTK Query
      headers.set('X-CSRF-Token', Rails.csrfToken());
      return headers;
    }
  }),
  endpoints: () => ({}) // Leave empty since endpoints will be added using `injectEndpoints` in slices
});
