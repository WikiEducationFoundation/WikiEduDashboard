// https://jestjs.io/docs/en/configuration.html

module.exports = {
  collectCoverage: false,

  projects: [
    // Configuration for legacy tests (without RTK/MSW)
    {
      displayName: 'legacy-tests',
      testMatch: ['<rootDir>/test/**/*.spec.js'], // Match all old test files

      // Transform settings to handle ESM modules that need conversion to CJS
      transformIgnorePatterns: ['/node_modules/(?!@react-dnd|react-dnd|dnd-core|react-dnd-html5-backend|lodash-es|i18n-js)'],

      setupFiles: ['./test/setup.js'], // Setup file specific to legacy tests

      // Define module resolution paths for easier imports in legacy tests
      roots: ['test', 'app/assets/javascripts'],
      moduleDirectories: ['test', 'app/assets/javascripts', 'node_modules']
    },

    // Configuration for (React-Redux Integration Tests)
    {
      displayName: 'React-Redux Integration Tests',
      testMatch: ['<rootDir>/test/components/**/*.test.jsx'], // Only run (React-Redux Integration Tests)
      testEnvironment: 'jsdom', // Simulate a browser environment for React tests

      // Additional setup files specifically for integration testing with RTK/MSW (React-Redux Integration Tests)
      setupFilesAfterEnv: ['<rootDir>/test/jest.integration-setup.js', '<rootDir>/test/mswSetupEnv.js'],

      // Handle ESM modules that require transformation for compatibility
      // @bundled-es-modules is one of the dependencies of MSW.
      transformIgnorePatterns: ['/node_modules/(?!@reduxjs/toolkit|lodash-es|@bundled-es-modules)']
    }
  ]
};
