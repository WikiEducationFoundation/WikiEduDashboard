import React from 'react';

// Enables DRY and simple conditional components
// Renders items when 'show' prop is undefined

const Conditional = function (Component) {
  return React.createClass({
    propTypes: {
      show: React.PropTypes.bool
    },

    render() {
      if (this.props.show === undefined || this.props.show) {
        return (<Component {...this.props} />);
      }
      return false;
    }
  });
};

export default Conditional;
