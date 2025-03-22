import { server } from './server.js'; // Import the MSW mock server instance

// Starts the mock server before all tests run.
// - Ensures that all network requests made in tests are intercepted by MSW.
// - This prevents actual API calls and allows controlled responses.
beforeAll(() => server.listen());

// Resets any request handlers added during individual tests after each test.
// - If a test modifies the mock server's behavior (e.g., adding a new request handler),
//   this ensures that subsequent tests are not affected.
// - Helps maintain "test isolation", preventing one test's behavior from leaking into another.
afterEach(() => server.resetHandlers());

// Closes the mock server after all tests have finished running.
// - Ensures proper cleanup and prevents memory leaks.
// - Stops the mock request interception, so it doesn’t persist beyond the test suite.
afterAll(() => server.close());
