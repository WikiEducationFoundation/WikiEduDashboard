import React from 'react';
import { Link } from 'react-router';

const Intro = React.createClass({
  propTypes: {
    currentUser: React.PropTypes.object,
    returnToParam: React.PropTypes.string,
    location: React.PropTypes.object
  },

  getInitialState() {
    return { user: this.props.currentUser };
  },

  render() {
    return (
      <div className="intro text-center">
        <h1>Hi {this.state.user.real_name || this.state.user.username}</h1>
        <p>We’re excited that you’re here!</p>
        <Link
          to={{
            pathname: '/onboarding/form',
            query: {
              return_to: decodeURIComponent(this.props.returnToParam)
            }
          }}
          className="button border inverse-border"
        >
          Start <i className="icon icon-rt_arrow" />
        </Link>
      </div>
    );
  }
});

export default Intro;
