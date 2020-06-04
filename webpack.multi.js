const jsConfig = require('./js.webpack');
const cssConfig = require('./css.webpack');

module.exports = env => [
  jsConfig(env),
  cssConfig(env)
];

