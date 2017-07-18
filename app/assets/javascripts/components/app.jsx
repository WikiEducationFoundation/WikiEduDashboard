import React from 'react';
import Nav from '../components/nav.jsx';
const App = React.createClass({
  displayName: 'App',

  propTypes: {
    children: React.PropTypes.node
  },

  getInitialState() {
    return {
      width: $(window).width(),
      height: $(window).height()
    };
  },

  render() {
    return (
      <div>
        <Nav
          main_app = {this.state.main_app}
        />
        {this.props.children}
      </div>
    );
  }
});

export default App;
