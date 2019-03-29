import React from 'react';

export const Reply = ({ message }) => {
  return (
    <div className="module mt0">
      <p dangerouslySetInnerHTML={{ __html: message.content }} />
      <p>- { message.sender }</p>
    </div>
  );
};

export default Reply;
