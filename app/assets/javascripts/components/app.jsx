import React from 'react';
import Notifications from './common/notifications.cjsx';

let App = React.createClass({
  displayName: 'App',
  render() {
    return <div>
      <Notifications />
      {this.props.children}
    </div>;
  }
});

export default App;
