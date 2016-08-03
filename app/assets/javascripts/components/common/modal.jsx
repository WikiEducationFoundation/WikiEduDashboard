import React from 'react';

const Modal = React.createClass({
  propTypes: {
    modalClass: React.PropTypes.string,
    children: React.PropTypes.node
  },
  componentWillMount() {
    return $('body').addClass('modal-open');
  },
  componentWillUnmount() {
    return $('body').removeClass('modal-open');
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
