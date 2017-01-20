import React from 'react';

const RocketChat = React.createClass({
  displayName: 'RocketChat',

  getInitialState() {
    return { loggedIn: true };
  },

  render() {
    let chatFrame;
    if (this.state.loggedIn) {
      chatFrame = <iframe style={{ display: 'block', width: '100%', height: '1000px' }} src="https://dashboardchat.wmflabs.org/" />;
    }

    return (

      <div className="modal">
        {chatFrame}
      </div>
    );
  }
});

export default RocketChat;
