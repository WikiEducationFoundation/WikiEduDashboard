import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { Link } from 'react-router';

const SlideLink = createReactClass({
  displayName: 'SlideLink',

  propTypes: {
    button: PropTypes.bool,
    disabled: PropTypes.bool,
    buttonText: PropTypes.string,
    params: PropTypes.object.isRequired,
    slideId: PropTypes.string.isRequired
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
    const href = this._slideLink(linkParams);
    return (
      <Link data-href={href} disabled={this.props.disabled} className={linkClass} to={href}>
        {this.props.buttonText}
      </Link>
    );
  }
});

export default SlideLink;
