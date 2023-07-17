import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const Finished = ({ returnToParam }) => {
  // When this route loads, wait a second then redirect
  // out to the return_to param (or root)
  useEffect(() => {
    const timeout = setTimeout(() => {
      const returnTo = returnToParam;
      window.location = decodeURIComponent(returnTo);
    }, 750);

    // clear the timeout just to be safe
    return () => { clearTimeout(timeout); };
  }, []);

  return (
    <div className="intro">
      <h1>You´re all set. Thank you.</h1>
      <h2>Loading...</h2>
    </div>
  );
};

Finished.propTypes = {
  returnToParam: PropTypes.string
};

export default Finished;
