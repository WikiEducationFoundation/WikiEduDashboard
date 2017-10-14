import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

// Enables DRY and simple conditional components
// Renders items when 'show' prop is undefined

const Conditional = function (Component) {
  return createReactClass({
    propTypes: {
      show: PropTypes.bool
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
