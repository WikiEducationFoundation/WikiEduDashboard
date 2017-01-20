import React from 'react';

const RocketChat = React.createClass({
  displayName: 'RocketChat',

  getInitialState() {
    return { showChat: false };
  },

  login() {
    this.setState({ showChat: true });

    // TODO:
    // If possible, start by checking if the user is already logged in to RocketChat.
    // If not, proceed with login flow.
    // First, request auth token from dashboard server

    // On success, use that token to log in:
    document.querySelector('iframe').contentWindow.postMessage({
      externalCommand: 'login-with-token',
      token: 'TOKEN-FROM-SERVER'
    }, '*');
    // Verify login success
    this.setState({ loggedIn: true });
  },

  render() {
    let chatFrame;
    // TODO: Hide chat until login succeeds.
    if (this.state.showChat) {
      chatFrame = <iframe id="chat" style={{ display: 'block', width: '100%', height: '1000px' }} src="https://dashboardchat.wmflabs.org/channel/general?layout=embedded" />;
    }

    return (
      <div className="modal">
        <button className="button dark" onClick={this.login} >Chat!</button>
        {chatFrame}
      </div>
    );
  }
});

export default RocketChat;
