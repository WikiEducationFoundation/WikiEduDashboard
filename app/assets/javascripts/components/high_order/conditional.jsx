import React from 'react';
import PropTypes from 'prop-types';

// Enables DRY and simple conditional components
// Renders items when 'show' prop is undefined

const Conditional = function (Component) {
  const ConditionalComponent = (props) => {
    if (props.show === undefined || props.show) {
      return (<Component {...props} />);
    }
    return false;
  };

  ConditionalComponent.displayName = `Conditional${Component.displayName}`;

  ConditionalComponent.propTypes = {
    show: PropTypes.bool
  };

  return ConditionalComponent;
};

export default Conditional;
