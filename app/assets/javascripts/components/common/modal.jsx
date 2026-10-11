import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const Modal = (props) => {
  useEffect(() => {
    document.querySelector('body')?.classList.add('modal-open');
    return () => {
      document.querySelector('body')?.classList.remove('modal-open');
    };
  }, []);

  // Escape is heard on the whole document, so it works wherever focus is.
  useEffect(() => {
    if (!props.onClose) return undefined;
    const closeOnEscape = (e) => {
      if (e.key === 'Escape') props.onClose();
    };
    document.addEventListener('keydown', closeOnEscape);
    return () => document.removeEventListener('keydown', closeOnEscape);
  }, [props.onClose]);

  // Only a click on the backdrop itself, not on the content over it.
  const closeOnBackdropClick = (e) => {
    if (e.target === e.currentTarget) props.onClose();
  };

  const className = `wizard active ${props.modalClass}`;
  return (
    // Keyboard users close it with Escape, above.
    // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions
    <div
      className={className}
      style={props.style}
      role="dialog"
      aria-modal={props.ariaModal === false ? undefined : 'true'}
      aria-label={props.ariaLabel}
      aria-labelledby={props.ariaLabelledBy}
      onClick={props.onClose ? closeOnBackdropClick : undefined}
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
  // Given, Escape and a click on the backdrop call it.
  onClose: PropTypes.func,
  style: PropTypes.object
};

export default Modal;
