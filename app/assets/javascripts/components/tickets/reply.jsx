import React from 'react';
import moment from 'moment';

import HelperIcon from './helper_icon';

export const Reply = ({ message }) => {
  const deliveredTime = moment(message.details.delivered).format('YYYY/MM/DD h:mm a');
  const delivered = `Delivered on ${deliveredTime}`;

  const failedTime = moment(message.details.delivery_failed).format('YYYY/MM/DD h:mm a');
  const failed = `Failed on ${failedTime}`;

  return (
    <React.Fragment>
      <section className="module mb0 mt0">
        <p dangerouslySetInnerHTML={{ __html: message.content }} />
      </section>
      <aside className="reply-details">
        <span>
          <p>From: {message.sender.real_name || message.sender.username}</p>
        </span>
        <span>
          <p>Created: {moment(message.created_at).format('MMM DD, YYYY h:mm a')}</p>
        </span>
        <span>
          {
            message.details.delivered
            && <HelperIcon imageName="check" altText={delivered} />
          }
          {
            message.details.delivery_failed
            && <HelperIcon imageName="minus" altText={failed} />
          }
        </span>
      </aside>
    </React.Fragment>
  );
};

export default Reply;
