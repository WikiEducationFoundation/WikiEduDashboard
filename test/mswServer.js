// Sets up a Mock Service Worker (MSW) server to intercept and handle API requests in tests.
// This ensures that network requests made by components are handled with predefined mock responses.

import { setupServer } from 'msw/node'; // MSW's Node.js version for handling API requests in Jest.
import { handlers } from './msw_handlers/server_handlers'; // Import all mock API handlers from `server_handlers.js`

// Creates an instance of the MSW server with the specified handlers.
// This allows us to intercept network requests and return mock responses.
export const server = setupServer(...handlers);
