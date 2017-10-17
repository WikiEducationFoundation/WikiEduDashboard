// Replacement for non-custom Link component. The react Link component doesn't highlight the active link if it is not handeled by react router, CustomLink is used to provide that functioning.
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const CustomLink = createReactClass({
  displayName: 'CustomLink',

  propTypes: {
    to: PropTypes.string,
    location: PropTypes.object,
    name: PropTypes.string,
    clickedElement: PropTypes.string,
    target: PropTypes.string
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
