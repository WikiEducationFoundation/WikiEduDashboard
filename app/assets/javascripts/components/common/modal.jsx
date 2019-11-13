import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const Modal = createReactClass({
  propTypes: {
    modalClass: PropTypes.string,
    children: PropTypes.node
  },
  componentWillUnmount() {
    return $('body').removeClass('modal-open');
  },
  UNSAFE_componentWillMount() {
    return $('body').addClass('modal-open');
  },
  render() {
    const className = `wizard active ${this.props.modalClass}`;
    return (
      <div className={className}>
        {this.props.children}
      </div>
    );
  }
}
);

export default Modal;
