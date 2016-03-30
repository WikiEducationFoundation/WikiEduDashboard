import React from 'react';
import Notifications from './common/notifications.cjsx';

const App = React.createClass({
  displayName: 'App',

  propTypes: {
    children: React.PropTypes.node
  },

  render() {
    return (
      <div>
        <Notifications />
        {this.props.children}
      </div>
    );
  }
});

export default App;
