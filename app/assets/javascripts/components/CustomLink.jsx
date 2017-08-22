import React from 'react';

const CustomLink = React.createClass({
  displayName: 'CustomLink',

  propTypes: {
    to: React.PropTypes.string,
    location: React.PropTypes.object,
    name: React.PropTypes.string,
    clickedElement: React.PropTypes.string,
    target: React.PropTypes.string
  },
  isActive() {
    let bool;
    const path = location.pathname.split('/')[1];
    if (path === this.props.clickedElement) {
      bool = true;
    } else {
      bool = false;
    }
    return bool;
  },
  render() {
    return <a href = {this.props.to} className={this.isActive() ? 'active' : ''} target={this.props.target}> {this.props.name} </a>;
  }
});

export default CustomLink;
