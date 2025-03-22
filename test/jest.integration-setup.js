// Polyfills 'fetch', 'Response', 'Request', etc. for environments (like Jest 26.0.1)
// that don't have native fetch support.
import 'whatwg-fetch';

// Imports 'TextEncoder' and 'TextDecoder' from Node.js 'util' module.
// Some environments (like older Jest versions 26.0.1) might not have these built-in,
// so we explicitly provide them.
import { TextEncoder, TextDecoder } from 'util';

// Provides custom Jest matchers for better assertions in tests, such as:
// - expect(element).toBeInTheDocument()
// - expect(element).toHaveTextContent('Hello')
import '@testing-library/jest-dom';

// Ensures 'TextEncoder' and 'TextDecoder' are globally available in Jest's test environment.
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;

// Jest's JSDOM environment lacks support for 'TransformStream', which is required by some APIs (like 'fetch').
// We manually polyfill it using Node.js' built-in `stream/web` module.
global.TransformStream = require('stream/web').TransformStream;

// Mock 'I18n.t()' function to prevent real translation calls during tests.
// Returns the key itself when 'I18n.t('some.translation.key')' is called.
global.I18n = {
  t: jest.fn(key => key) // Mock function that returns the input key instead of translating.
};

// Jest version 26.0.1 and some older environments do not have 'BroadcastChannel'
// which is required by some real-time communication features (like WebSockets, service workers, etc.).
// This provides a basic mock implementation to avoid errors in tests.
class MockBroadcastChannel {
  constructor() {
    this.onmessage = () => {}; // Mock 'onmessage' event handler
  }
  postMessage() {} // Mock 'postMessage' method
  close() {} // Mock 'close' method
}

// Assigns the mock 'BroadcastChannel' globally to prevent Jest from throwing errors.
global.BroadcastChannel = MockBroadcastChannel;
