// https://jestjs.io/docs/en/configuration.html

module.exports = {
  collectCoverage: false,
  roots: [
    'test',
    'app/assets/javascripts'
  ],
  moduleDirectories: [
    'test',
    'app/assets/javascripts',
    'node_modules'
  ],

  // all these are ESM modules which must be converted to CJS
  transformIgnorePatterns: [
    '/node_modules/(?!@reduxjs/toolkit|@react-dnd|react-dnd|dnd-core|react-dnd-html5-backend|lodash-es|i18n-js|@bundled-es-modules)',
  ],
  setupFiles: ['./test/setup.js'],
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js', '<rootDir>/test/setup_env.js'],
  // Ensures a browser-like environment for React tests
  testEnvironment: 'jsdom',
};
