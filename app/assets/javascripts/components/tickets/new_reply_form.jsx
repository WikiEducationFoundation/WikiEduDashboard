import React, { useEffect, useState } from 'react';

import TextAreaInput from '../common/text_area_input.jsx';
import TextInput from '../common/text_input.jsx';
import { MESSAGE_KIND_NOTE, MESSAGE_KIND_REPLY, TICKET_STATUS_AWAITING_RESPONSE, TICKET_STATUS_RESOLVED } from '../../constants/tickets';
import { INSTRUCTOR_ROLE } from '../../constants/user_roles';
import {
  createReply,
  fetchTicket,
} from '../../actions/tickets_actions';
import { useDispatch } from 'react-redux';

const isBlank = (string) => {
  if (/\S/.test(string)) {
    return false;
  }
  return true;
};

const NewReplyForm = ({ ticket, currentUser }) => {
  const dispatch = useDispatch();
  const [replyDetails, setReplyDetails] = useState({
    cc: '',
    content: '',
    plainText: '',
    sending: false,
    showCC: false,
    bccToSalesforce: false
  });

  useEffect(() => {
    setReplyDetails(prevState => ({ ...prevState, bccToSalesforce: ticket.sender.role === INSTRUCTOR_ROLE }));
  }, [ticket]);

  const onChange = (_key, content) => {
    setReplyDetails(prevState => ({ ...prevState, [_key]: content }));
  };

  const onTextAreaChange = (_key, content, _e) => {
    setReplyDetails(prevState => ({
      ...prevState, content: content, plainText: content
    }));
  };

  const onCCClick = (e) => {
    e.preventDefault();
    setReplyDetails(prevState => ({
      ...prevState, showCC: !prevState.showCC
    }));
  };

  const onReply = (e) => {
    setReplyDetails(prevState => ({ ...prevState, sending: true }));
    onSubmit(e, TICKET_STATUS_AWAITING_RESPONSE, MESSAGE_KIND_REPLY);
  };

  const onCreateNote = (e) => {
    setReplyDetails(prevState => ({ ...prevState, sending: true }));
    onSubmit(e, ticket.status, MESSAGE_KIND_NOTE); // Leave status unchanged
  };

  const onResolve = (e) => {
    setReplyDetails(prevState => ({ ...prevState, sending: true }));
    onSubmit(e, TICKET_STATUS_RESOLVED, MESSAGE_KIND_REPLY);
  };

  const onSubmit = (e, status, kind) => {
    e.preventDefault();
    if (isBlank(replyDetails.plainText)) {
      setReplyDetails(prevState => ({ ...prevState, sending: false }));
      return;
    }

    const { cc, content, bccToSalesforce } = replyDetails;
    const ccEmails = _ccEmailsSplit(cc);
    if (!_ccEmailsAreValid(ccEmails)) {
      setReplyDetails(prevState => ({ ...prevState, sending: false }));
      return;
    }
    let body = {
      content,
      kind,
      ticket_id: ticket.id,
      sender_id: currentUser.id,
      read: true
    };

    if (replyDetails.cc) {
      const details = { cc: ccEmails.map(email => ({ email })) };
      body = { ...body, details };
    }

    dispatch(createReply(body, status, bccToSalesforce))
      .then(() => dispatch(fetchTicket(ticket.id)))
      .then(() => setReplyDetails(prevState => ({ ...prevState, cc: '', content: '', sending: false }))
      );
  };
  const toggleBcc = (e) => {
    setReplyDetails(prevState => ({ ...prevState, bccToSalesforce: e.target.checked }));
  };

  const _ccEmailsSplit = (emailString = '') => {
    return emailString.split(',')
      .map(email => email.trim())
      .filter(email => email);
  };

  const _ccEmailsAreValid = (emails) => {
    if (!emails.length) return true;
    const regexp = RegExp(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i);
    return emails.every(email => regexp.test(email));
  };

  const name = ticket.sender && (ticket.sender.real_name || ticket.sender.username);
  const toAddress = name ? ` to ${name}` : null;
  // Using the lastTicketId for the input key means that a new, blank
  // input will be created after a new message is successfully added.
  const lastTicketId = ticket.messages[ticket.messages.length - 1].id;
  return (
    <form className="tickets-reply">
      <h3>
        Send a Reply{toAddress}
        <button
          alt="Show BCC"
          title="Show BCC"
          className="button border plus"
          onClick={onCCClick.bind(this)}
        >
          +
        </button>
        <div className="pull-right">
          <small>
            BCC to Salesforce
            <input
              checked={replyDetails.bccToSalesforce}
              className="ml1 top2"
              id="bcc"
              name="bcc"
              onChange={toggleBcc.bind(this)}
              type="checkbox"
            />
          </small>
        </div>
      </h3>
      {
        replyDetails.showCC
        && (
          <div className="cc-fields">
            <label>CC:</label>
            <TextInput
              id="cc"
              onChange={onChange.bind(this)}
              value={replyDetails.cc}
              value_key="cc"
              editable
              placeholder={'Place emails here, separated by commas'}
            />
          </div>
        )
      }
      <div className="bg-white">
        <TextAreaInput
          key={`reply-to-${lastTicketId}`}
          id="content"
          editable
          label="Enter your reply"
          onChange={onTextAreaChange.bind(this)}
          value={replyDetails.content}
          value_key="content"
          wysiwyg={true}
        />
      </div>
      <button
        className="button dark margin right mt2"
        disabled={replyDetails.sending}
        id="reply-resolve"
        onClick={onResolve.bind(this)}
        type="submit"
      >
        Send Reply and Resolve Ticket
      </button>
      <button
        className="button dark right mt2"
        disabled={replyDetails.sending}
        id="reply"
        onClick={onReply.bind(this)}
        type="submit"
      >
        Send Reply
      </button>
      <button
        className="button left mt2"
        disabled={replyDetails.sending}
        id="create-note"
        onClick={onCreateNote.bind(this)}
        type="submit"
      >
        Create Note
      </button>
    </form>
  );
};

export default NewReplyForm;
