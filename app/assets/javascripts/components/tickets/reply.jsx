import React from 'react';
import moment from 'moment';

import HelperIcon from './helper_icon';

export const Reply = ({ message }) => {
  const deliveredTime = moment(message.details.delivered).format('YYYY/MM/DD h:mm a');
  const delivered = `Delivered on ${deliveredTime}`;

  const failedTime = moment(message.details.delivery_failed).format('YYYY/MM/DD h:mm a');
  const failed = `Failed on ${failedTime}`;

  return (
    <div className="module mt0">
      <p dangerouslySetInnerHTML={{ __html: message.content }} />
      <p>- { message.sender }</p>
      <div>
        <span>Read on: {moment(message.updated_at).format('YYYY/MM/DD h:mm a')}</span>
        {
          message.details.delivered
          && <HelperIcon imageName="check" altText={delivered} />
        }
        {
          message.details.delivery_failed
          && <HelperIcon imageName="minus" altText={failed} />
        }
      </div>
    </div>
  );
};

export default Reply;
