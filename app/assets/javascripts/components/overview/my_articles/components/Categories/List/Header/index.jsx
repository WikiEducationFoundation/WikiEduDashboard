import React from 'react';

// components
import Tooltip from './Tooltip';

export default ({ message, sub, title }) => {
  const smallText = (
    <Tooltip message={message} text={sub} />
  );
  return (
    <h4 className="mb1 mt2">{title} {sub && smallText}</h4>
  );
};
