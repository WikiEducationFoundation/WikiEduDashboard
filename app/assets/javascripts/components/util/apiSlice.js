// Import the RTK Query methods from the React-specific entry point
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import Rails from '@rails/ujs';

// Define our single API slice object
export const apiSlice = createApi({
  // A unique key for the Redux store slice where this API's state will be stored.
  reducerPath: 'api',

  // Configure how API requests are made
  baseQuery: fetchBaseQuery({
    // Set the base URL dynamically
    // a) In test (`NODE_ENV === 'test'`), use 'http://locahost' to match MSW.
    // b) In other environments, use an empty string (assumes absolute URLs are used elsewhere).
    baseUrl: process.env.NODE_ENV === 'test' ? 'http://localhost' : '',

    // Add headers to API requests (if needed)
    prepareHeaders: (headers, api) => {
      if (api.type === 'mutation') {
        headers.set('X-CSRF-Token', Rails.csrfToken());
      }

      // Return modified headers
      return headers;
    }
  }),

  // Define API endpoints separately using `injectEndpoints()`
  endpoints: () => ({})
});
