import React from 'react';

export default ({ message, text }) => {
  return (
    <div className="tooltip-trigger">
      <small className="peer-review-count">{text}</small>
      <div className="tooltip dark">
        <p>
          {message}
        </p>
      </div>
    </div>
  );
};
