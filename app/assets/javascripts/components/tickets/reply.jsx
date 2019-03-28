import React from 'react';

export const Reply = ({ message }) => {
  return (
    <div className="module mt0">
      <p>{ message.content }</p>
      <p>- { message.sender }</p>
    </div>
  );
};

export default Reply;
