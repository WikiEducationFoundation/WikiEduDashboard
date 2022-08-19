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
    '/node_modules/(?!@react-dnd|react-dnd|dnd-core|react-dnd-html5-backend|lodash-es|i18n-js)',
  ],
  setupFiles: ['./test/setup.js'],
};
