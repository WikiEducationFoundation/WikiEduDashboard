import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const App = createReactClass({
  displayName: 'App',

  propTypes: {
    children: PropTypes.node
  },

  render() {
    return (
      <div>
        {this.props.children}
      </div>
    );
  }
});

export default App;
