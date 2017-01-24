import React from 'react';
import ChatActions from '../../actions/chat_actions.js';
import ChatStore from '../../stores/chat_store.js';

const RocketChat = React.createClass({
  displayName: 'RocketChat',

  propTypes: {
    course: React.PropTypes.object
  },

  mixins: [ChatStore.mixin],

  getInitialState() {
    return {
      authToken: ChatStore.getAuthToken()
    };
  },

  componentWillMount() {
    if (!this.state.authToken) {
      ChatActions.requestAuthToken();
    }
  },

  storeDidChange() {
    this.setState({
      authToken: ChatStore.getAuthToken()
    });
    this.loginOnFrameLoad();
  },

  loginOnFrameLoad() {
    document.querySelector('iframe').onload = this.login;
  },

  login() {
    document.querySelector('iframe').contentWindow.postMessage({
      externalCommand: 'login-with-token',
      token: this.state.authToken
    }, '*');
  },

  render() {
    // Rocket.Chat appears to double-encode the channel name to produce the URI.
    const channel = encodeURIComponent(encodeURIComponent(this.props.course.slug));
    const chatUrl = `https://dashboardchat.wmflabs.org/channel/${channel}?layout=embedded`;
    const chatFrame = <iframe id="chat" className="iframe" src={chatUrl} />;

    return (
      <div className="rocket-chat">
        {chatFrame}
      </div>
    );
  }
});

export default RocketChat;
