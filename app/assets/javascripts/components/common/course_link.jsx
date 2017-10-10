import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { Link } from 'react-router';

const CourseLink = createReactClass({
  displayName: 'CourseLink',

  propTypes: {
    to: PropTypes.string,
    onClick: PropTypes.func,
    className: PropTypes.string,
    children: PropTypes.node
  },

  render() {
    return (
      <Link
        to={this.props.to}
        onClick={this.props.onClick}
        className={this.props.className}
      >
        {this.props.children}
      </Link>
    );
  }
}
);

export default CourseLink;
