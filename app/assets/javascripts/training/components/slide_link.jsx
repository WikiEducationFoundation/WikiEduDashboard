import React from 'react';
import { Link } from 'react-router';

const SlideLink = React.createClass({
  displayName: 'SlideLink',

  propTypes: {
    button: React.PropTypes.bool,
    disabled: React.PropTypes.bool,
    direction: React.PropTypes.string.isRequired,
    params: React.PropTypes.object.isRequired,
    slideId: React.PropTypes.string.isRequired
  },

  linkParams(props) {
    return {
      library_id: props.params.library_id,
      module_id: props.params.module_id,
      slide_id: props.slideId
    };
  },

  _slideLink(props) {
    return `/training/${props.library_id}/${props.module_id}/${props.slide_id}`;
  },

  render() {
    const linkParams = this.linkParams(this.props);
    const buttonClasses = ' btn btn-primary icon icon-rt_arrow';
    let linkClass = 'slide-nav';
    linkClass += this.props.button ? buttonClasses : '';
    let href = this._slideLink(linkParams);
    return (
      <Link data-href={href} disabled={this.props.disabled} className={linkClass} to={href}>
        {this.props.direction} Page
      </Link>
    );
  }
});

export default SlideLink;
