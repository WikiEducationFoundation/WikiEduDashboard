import React from 'react';
// import { Route } from 'react-router';

const CustomLink = React.createClass({
  displayName: 'CustomLink',

  propTypes: {
    to: React.PropTypes.string,
    location: React.PropTypes.object,
    activeClassName: React.PropTypes.string,
    name: React.PropTypes.string
  },
  render() {
    return <a href = {this.props.to} >{this.props.name}</a>;
    // return <a href = {this.props.to} className={isActive ? 'active' : ''} />;
  }
});

export default CustomLink;
