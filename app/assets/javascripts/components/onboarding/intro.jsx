import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { Link } from 'react-router';

const Intro = createReactClass({
  propTypes: {
    currentUser: PropTypes.object,
    returnToParam: PropTypes.string,
    location: PropTypes.object
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
