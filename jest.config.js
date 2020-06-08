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
  transformIgnorePatterns: [
    '/node_modules/(?!lodash-es)'
  ]
};
