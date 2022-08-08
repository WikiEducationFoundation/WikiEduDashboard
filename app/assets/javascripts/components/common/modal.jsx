import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const Modal = createReactClass({
  propTypes: {
    modalClass: PropTypes.string,
    children: PropTypes.node
  },
  componentDidMount() {
    return document.querySelector('body')?.classList.add('modal-open');
  },
  componentWillUnmount() {
    return document.querySelector('body')?.classList.remove('modal-open');
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
