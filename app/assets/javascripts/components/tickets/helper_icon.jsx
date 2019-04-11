import React from 'react';

export default ({ imageName, altText }) => {
  return (
    <img
      className={`${imageName} status-icon tooltip-trigger`}
      src={`/assets/images/${imageName}.svg`}
      alt={altText}
      title={altText}
    />
  );
};
