import React from 'react';
import PropTypes from 'prop-types';

const App = React.createClass({
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
