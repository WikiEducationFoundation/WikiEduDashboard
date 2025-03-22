// This file defines all request handlers for MSW (Mock Service Worker).
// It centralizes API mocking logic to ensure consistency across tests.
// Instead of defining handlers directly in 'server.js', we import them from separate modules
// (like 'adminCourseNotesHandlers') to keep things organized and maintainable.
import { adminCourseNotesHandlers } from './handlers/adminCourseNotesHandlers';

// 'handlers' is an array that contains all API request handlers used in tests.
// This allows the mock server ('test/server.js') to intercept and respond to API requests during testing.
export const handlers = [
  ...adminCourseNotesHandlers // Includes all handlers related to Admin Course Notes API
];
