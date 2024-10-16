import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

const SlideLink = ({ button, params, slideId, onClick, disabled, buttonText, isPrevious = false }) => {
  const linkClass = `slide-nav ${button ? `btn ${isPrevious ? 'previous-button' : 'btn-primary next-button'}` : ''}`;

  const href = `/training/${params.library_id}/${params.module_id}/${slideId}`;

  const buttonStyle = isPrevious ? { backgroundColor: '#6c757d', color: 'white' } : {};

  return (
    <Link data-href={href} onClick={onClick} disabled={disabled} className={linkClass} to={href} style={buttonStyle}>
      {isPrevious ? <i className="icon icon-lt_arrow_white_training" /> : ''}
      {buttonText}
      {button && !isPrevious ? <i className="icon icon-rt_arrow_white_training" /> : ''}
    </Link>
  );
};

SlideLink.propTypes = {
  button: PropTypes.bool,
  params: PropTypes.object.isRequired,
  slideId: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
  disabled: PropTypes.bool,
  buttonText: PropTypes.string,
  isPrevious: PropTypes.bool,
};

export default SlideLink;
