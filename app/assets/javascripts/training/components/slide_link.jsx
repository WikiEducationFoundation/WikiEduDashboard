import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

const SlideLink = ({ button, params, slideId, onClick, disabled, buttonText }) => {
  const linkClass = `slide-nav ${button ? 'btn btn-primary icon icon-rt_arrow' : ''}`;
  const href = `/training/${params.library_id}/${params.module_id}/${slideId}`;
  return (
    <Link data-href={href} onClick={onClick} disabled={disabled} className={linkClass} to={href}>
      {buttonText}
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
};

export default SlideLink;
