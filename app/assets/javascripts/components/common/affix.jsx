import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

const Affix = ({ className, offset = 0, children }) => {
  const [affix, setAffix] = useState(false);
  useEffect(() => {
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleScroll = () => {
    const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;

    if (!affix && scrollTop >= offset) { setAffix(true); }
    if (affix && scrollTop < offset) { setAffix(false); }
  };

  return (
    <div className={`${className} ${affix === true ? 'affix' : ''}`}>
      {children}
    </div>
  );
};

Affix.propTypes = {
  offset: PropTypes.number,
  className: PropTypes.string,
  children: PropTypes.node
};

export default Affix;
