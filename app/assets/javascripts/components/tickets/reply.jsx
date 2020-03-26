import React from 'react';
import moment from 'moment';
import linkifyHtml from 'linkifyjs/html';

import { MESSAGE_KIND_NOTE } from '../../constants/tickets';
import HelperIcon from './helper_icon';
import DeleteNote from './delete_note';

export const Reply = ({ message }) => {
  const { sender, details } = message;

  const deliveredTime = moment(details.delivered).format('YYYY/MM/DD h:mm a');
  const delivered = `Delivered on ${deliveredTime}`;

  const failedTime = moment(details.delivery_failed).format('YYYY/MM/DD h:mm a');
  const failed = `Failed on ${failedTime}`;

  let subject;
  let messageClass;
  if (details.subject) {
    subject = (
      <h4 className="subject">{ details.subject }</h4>
    );
  } else if (message.kind === MESSAGE_KIND_NOTE) {
    messageClass = 'tickets-note';
    subject = (
      <div className="note-heading">
        <h4 className="subject">NOTE</h4>
        <DeleteNote messageId={message.id} />
      </div>
    );
  }

  let cc;
  if (details.cc) {
    cc = (
      <h6 className="cc">
        <span>CC: </span>
        {details.cc.map(({ email }) => email).join(', ')}
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
        <span className="from">
          <p>From: {from}</p>
        </span>
        <span className="created-at">
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
