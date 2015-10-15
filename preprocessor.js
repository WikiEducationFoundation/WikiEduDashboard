var coffee = require('coffee-script');
var transform = require('coffee-react-transform');

module.exports = {
  process: function(src, path) {
    if (coffee.helpers.isCoffee(path)) {
      compiled_cjx = transform(src);
      compiled_to_react = coffee.compile(compiled_cjx, {bare: true});

      return compiled_to_react;
    }

    return src;
  }
};
