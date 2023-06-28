import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';

const Affix = ({ className, offset = 0, children }) => {
  const [affix, setAffix] = useState(false);
  const affixRef = useRef(affix);

  useEffect(() => {
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => affixRef.current = affix, [affix]);

  const handleScroll = () => {
    const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;

    if (!affixRef.current && scrollTop >= offset) {
      setAffix(true);
    }
    if (affixRef.current && scrollTop < offset) {
      setAffix(false);
    }
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
