import React from 'react';
import moment from 'moment';
import linkifyHtml from 'linkifyjs/html';

import { MESSAGE_KIND_NOTE } from '../../constants/tickets';
import HelperIcon from './helper_icon';

export const Reply = ({ message }) => {
  const deliveredTime = moment(message.details.delivered).format('YYYY/MM/DD h:mm a');
  const delivered = `Delivered on ${deliveredTime}`;

  const failedTime = moment(message.details.delivery_failed).format('YYYY/MM/DD h:mm a');
  const failed = `Failed on ${failedTime}`;

  const { sender, details } = message;
  let subject;
  let messageClass;
  if (details.subject) {
    subject = (
      <h4>{ details.subject }</h4>
    );
  } else if (message.kind === MESSAGE_KIND_NOTE) {
    messageClass = 'tickets-note';
    subject = (
      <h4>NOTE</h4>
    );
  }

  let cc;
  if (details.cc) {
    cc = (
      <h6 className="cc">
        <span>CC: </span>
        {details.cc.map(({ email }) => email)}
      </h6>
    );
  }

  const from = sender.real_name || sender.username || details.sender_email;
  return (
    <div className={messageClass} >
      <section className="reply-header module mb0 mt0">
        {subject}
        { cc }
        { (subject || cc) && <hr /> }
        <div className="plaintext message-body" dangerouslySetInnerHTML={{ __html: linkifyHtml(message.content) }} />
      </section>
      <aside className="reply-details">
        <span>
          <p>From: {from}</p>
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
    </div>
  );
};

export default Reply;
