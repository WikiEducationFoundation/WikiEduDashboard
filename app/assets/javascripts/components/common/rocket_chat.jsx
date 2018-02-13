import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { requestAuthToken, enableForCourse } from '../../actions/chat_actions.js';

const RocketChat = createReactClass({
  displayName: 'RocketChat',

  propTypes: {
    course: PropTypes.object,
    current_user: PropTypes.object,
    authToken: PropTypes.string,
    requestAuthToken: PropTypes.func,
    enableForCourse: PropTypes.func,
  },
  getInitialState() {
    return {
      showChat: false,
    };
  },

  componentWillMount() {
    if (Features.enableChat && !this.props.authToken) {
      this.props.requestAuthToken();
    }
  },

  componentDidMount() {
    if (Features.enableChat && this.props.authToken && !this.state.showChat) {
      this.loginOnFrameLoad();
    }
  },

  loginOnFrameLoad() {
    document.querySelector('iframe').onload = this.login;
  },

  login() {
    document.querySelector('iframe').contentWindow.postMessage({
      externalCommand: 'login-with-token',
      token: this.props.authToken
    }, '*');
    this.setState({ showChat: true });
  },

  render() {
    if (!(this.props.course && this.props.course.flags && this.props.course.flags.enable_chat)) {
      return <div />;
    }

    const privacyInfo = (
      <p>This chatroom is accessible to students and instructors participating in the course, as well as Wiki Ed staff.</p>
    );

    // Rocket.Chat appears to double-encode the channel name to produce the URI.
    const room = encodeURIComponent(encodeURIComponent(this.props.course.slug));
    const chatUrl = `https://dashboardchat.wmflabs.org/group/${room}?layout=embedded`;
    let chatClass = 'iframe';
    if (!this.props.authToken) {
      chatClass += ' hidden';
    }
    const chatFrame = <iframe id="chat" title="rocket chat" className={chatClass} src={chatUrl} />;

    let loginRetryButton;
    if (this.state.showChat) {
      loginRetryButton = <a className="pull-right button small" onClick={this.login} target="_blank">Retry login</a>;
    }

    return (
      <div className="rocket-chat">
        <a className="pull-right button small" href={`${window.location.origin}/feedback?subject=Course Chat`} target="_blank">Have a problem with chat? Let us know.</a>
        {privacyInfo}
        {chatFrame}
        {loginRetryButton}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  authToken: state.authToken,
});

const mapDispatchToProps = {
  requestAuthToken: requestAuthToken,
  enableForCourse: enableForCourse,
};

export default connect(mapStateToProps, mapDispatchToProps)(RocketChat);
