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
      style={props.style}
      role="dialog"
      aria-modal={props.ariaModal === false ? undefined : 'true'}
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
  ariaLabelledBy: PropTypes.string,
  // false for an overlay that leaves part of the page usable, so assistive
  // technology does not hide that part.
  ariaModal: PropTypes.bool,
  style: PropTypes.object
};

export default Modal;
