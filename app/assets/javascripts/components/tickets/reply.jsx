import React from 'react';
import DOMPurify from 'dompurify';
import linkifyHtml from 'linkify-html';

import { MESSAGE_KIND_NOTE } from '../../constants/tickets';
import HelperIcon from './helper_icon';
import DeleteNote from './delete_note';
import { formatDateWithTime } from '../../utils/date_utils';

// Message content arrives in two shapes. Replies composed in the WYSIWYG editor
// are HTML, and that is exactly what the recipient receives, since the mailer
// renders the content raw. Inbound email replies are plain text with real
// newlines (see EmailProcessor). So detect which shape a message is in by
// looking for the block markup an editor message always carries: HTML renders
// with its own block structure, while plain text keeps relying on
// `white-space: pre-line` to turn its newlines into breaks.
const BLOCK_MARKUP = /<(?:p|br|div|ul|ol|li|h[1-6]|blockquote|pre)\b[^>]*>/i;

// The tags the WYSIWYG editor can emit, plus the basics used by messages from
// the earlier TinyMCE editor. Attributes stay limited to link targets, so
// nothing here can carry a script handler.
const RICH_TEXT_TAGS = [
  'a', 'b', 'blockquote', 'br', 'code', 'div', 'em', 'h1', 'h2', 'h3', 'h4',
  'h5', 'h6', 'hr', 'i', 'li', 'ol', 'p', 'pre', 's', 'strong', 'u', 'ul'
];

const sanitizedBody = (content) => {
  const isHtml = BLOCK_MARKUP.test(content);
  const linkified = linkifyHtml(content, { target: { url: '_blank' } });
  return {
    isHtml,
    html: DOMPurify.sanitize(linkified, {
      ALLOWED_TAGS: isHtml ? RICH_TEXT_TAGS : ['a'],
      ALLOWED_ATTR: ['href', 'target', 'rel']
    })
  };
};

export const Reply = ({ message }) => {
  const { sender, details } = message;
  let delivered_message;
  let failed_message;
  if (details.delivered) {
    const deliveredTime = formatDateWithTime(details.delivered);
    delivered_message = `Delivered on ${deliveredTime}`;
  }

  if (details.delivery_failed) {
    const failedTime = formatDateWithTime(details.delivery_failed);
    failed_message = `Failed on ${failedTime}`;
  }

  let subject;
  let messageClass;
  if (details.subject) {
    subject = (
      <h3 className="subject">{ details.subject }</h3>
    );
  } else if (message.kind === MESSAGE_KIND_NOTE) {
    messageClass = 'tickets-note';
    subject = (
      <div className="note-heading">
        <h3 className="subject">NOTE</h3>
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
  const body = sanitizedBody(message.content);
  return (
    <div className={messageClass} >
      <section className="reply-header module mb0 mt0">
        {subject}
        { cc }
        { (subject || cc) && <hr /> }
        <div
          className={`message-body ${body.isHtml ? 'rich-text' : 'plaintext'}`}
          dangerouslySetInnerHTML={{ __html: body.html }}
        />
      </section>
      <div className="reply-details">
        <span className="from">
          <p>From: {from}</p>
        </span>
        <span className="created-at">
          <p>Created: {formatDateWithTime(message.created_at)}</p>
        </span>
        <span>
          {
            delivered_message
            && <HelperIcon imageName="check" altText={delivered_message} />
          }
          {
            failed_message
            && <HelperIcon imageName="minus" altText={failed_message} />
          }
        </span>
      </div>
    </div>
  );
};

export default Reply;
