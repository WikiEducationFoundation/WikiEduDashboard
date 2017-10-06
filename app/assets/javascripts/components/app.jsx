import React from 'react';


const App = React.createClass({
  displayName: 'App',

  propTypes: {
    children: React.PropTypes.node
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
