import React from 'react';
import PropTypes from 'prop-types';

// Enables DRY and simple conditional components
// Renders items when 'show' prop is undefined

const Conditional = (Component) => {
  const HighOrderComponent = (props) => {
    if (props.show) {
      return <Component {...props} />;
    }
    return null;
  };

  HighOrderComponent.propTypes = {
    show: PropTypes.bool.isRequired
  };

  HighOrderComponent.defaultProps = {
    show: true
  };

  return HighOrderComponent;
};

export default Conditional;
