import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const Modal = (props) => {
  useEffect(() => {
    document.querySelector('body')?.classList.add('modal-open');
    return () => {
      document.querySelector('body')?.classList.remove('modal-open');
    };
  }, []);

  const className = `wizard active ${props.modalClass}`;
  return (
    <div
      className={className}
      role="dialog"
      aria-modal="true"
      aria-label={props.ariaLabel}
      aria-labelledby={props.ariaLabelledBy}
    >
      {props.children}
    </div>
  );
};

Modal.propTypes = {
  modalClass: PropTypes.string,
  children: PropTypes.node,
  ariaLabel: PropTypes.string,
  ariaLabelledBy: PropTypes.string
};

export default Modal;
