import React from 'react';

import TextAreaInput from '../common/text_area_input.jsx';
import { TICKET_STATUS_AWAITING_RESPONSE, TICKET_STATUS_RESOLVED } from '../../constants/tickets';

const isBlank = (string) => {
  if (/\S/.test(string)) {
    return false;
  }
  return true;
};

export class NewReplyForm extends React.Component {
  constructor() {
    super();
    this.state = {
      content: '',
      plainText: ''
    };
  }

  onChange(_key, content, e) {
    this.setState({
      content,
      plainText: e.target.getContent({ format: 'text' })
    });
  }

  onReply(e) {
    this.onSubmit(e, TICKET_STATUS_AWAITING_RESPONSE);
  }

  onResolve(e) {
    this.onSubmit(e, TICKET_STATUS_RESOLVED);
  }

  onSubmit(e, status) {
    e.preventDefault();
    if (isBlank(this.state.plainText)) { return; }

    const content = this.state.content;
    const { currentUser, ticket } = this.props;
    const csrf = document.querySelector("meta[name='csrf-token']").getAttribute('content');
    const body = {
      content,
      kind: 0,
      ticket_id: ticket.id,
      sender_id: currentUser.id,
      read: true,
    };

    this.props.createReply(body, csrf, status)
      .then(() => this.props.fetchTicket(ticket.id))
      .then(() => this.setState({ content: '' }));
  }

  render() {
    const ticket = this.props.ticket;
    const toAddress = ticket.sender ? ` to ${ticket.sender}` : null;
    // Using the lastTicketId for the input key means that a new, blank
    // input will be created after a new message is successfully added.
    const lastTicketId = ticket.messages[ticket.messages.length - 1].id;
    return (
      <form>
        <h3>Send a Reply{toAddress}</h3>
        <div className="bg-white">
          <TextAreaInput
            key={`reply-to-${lastTicketId}`}
            id="content"
            editable
            label="Enter your reply"
            onChange={this.onChange.bind(this)}
            value={this.state.content}
            value_key="content"
            wysiwyg={true}
          />
        </div>
        <button className="button dark margin right mt2" type="submit" onClick={this.onResolve.bind(this)}>Send Reply and Resolve Ticket</button>
        <button className="button dark right mt2" type="submit" onClick={this.onReply.bind(this)}>Send Reply</button>
      </form>
    );
  }
}

export default NewReplyForm;
