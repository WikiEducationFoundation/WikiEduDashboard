import React from 'react';
import Nav from '../components/nav.jsx';

const getState = function () {
  const rootUrl = $('#react_root').data('rootUrl');
  console.log(rootUrl);
  return {
    rootUrl: rootUrl
  };
};

const App = React.createClass({
  displayName: 'App',

  propTypes: {
    children: React.PropTypes.node
  },

  getInitialState() {
    return getState();
  },

  render() {
    return (
      <div>
        <Nav
          main_app = {this.state.rootUrl}
        />
        {this.props.children}
      </div>
    );
  }
});

export default App;
