import React from 'react';
import moment from 'moment';

export const Reply = ({ message }) => {
  return (
    <div className="module mt0">
      <p dangerouslySetInnerHTML={{ __html: message.content }} />
      <p>- { message.sender }</p>
      <p>Read on: {moment(message.updated_at).format('YYYY/MM/DD h:mm a')}</p>
    </div>
  );
};

export default Reply;
