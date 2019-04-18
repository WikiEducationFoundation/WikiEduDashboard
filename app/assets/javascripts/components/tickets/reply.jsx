import React from 'react';
import moment from 'moment';
import linkifyHtml from 'linkifyjs/html';

import HelperIcon from './helper_icon';

export const Reply = ({ message }) => {
  const deliveredTime = moment(message.details.delivered).format('YYYY/MM/DD h:mm a');
  const delivered = `Delivered on ${deliveredTime}`;

  const failedTime = moment(message.details.delivery_failed).format('YYYY/MM/DD h:mm a');
  const failed = `Failed on ${failedTime}`;

  let subject;
  if (message.details.subject) {
    subject = (
      <React.Fragment>
        <h4>{ message.details.subject }</h4>
        <hr />
      </React.Fragment>
    );
  }

  let cc;
  if (message.details.cc) {
    cc = (
      <React.Fragment>
        <h6 className="cc">
          <span>CC: </span>
          {message.details.cc.map(({ email }) => email)}
        </h6>
      </React.Fragment>
    );
  }

  return (
    <React.Fragment>
      <section className="module mb0 mt0">
        {subject}
        { cc }
        <div className="plaintext message-body" dangerouslySetInnerHTML={{ __html: linkifyHtml(message.content) }} />
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
