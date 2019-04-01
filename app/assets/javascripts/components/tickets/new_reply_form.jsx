import React from 'react';

import TextAreaInput from '../common/text_area_input.jsx';

export class NewReplyForm extends React.Component {
  constructor() {
    super();
    this.state = {
      content: ''
    };
  }

  onChange(_key, content) {
    this.setState({ content });
  }

  onSubmit(e) {
    e.preventDefault();
    const { currentUser, ticket } = this.props;
    const content = this.state.content;
    const csrf = document.querySelector("meta[name='csrf-token']").getAttribute('content');
    const body = {
      content,
      csrf,
      kind: 0,
      ticket_id: ticket.id,
      sender_id: currentUser.id,
      read: true
    };

    this.props.createReply(body)
      .then(() => this.props.fetchTicket(ticket.id))
      .then(() => this.setState({ content: '' }));
  }

  render() {
    const ticket = this.props.ticket;
    const toAddress = ticket.sender ? ` to ${ticket.sender}` : null;
    return (
      <form onSubmit={this.onSubmit.bind(this)}>
        <h3>Send a Reply{toAddress}</h3>
        <div className="bg-white">
          <TextAreaInput
            id="content"
            editable
            label="Enter your reply"
            onChange={this.onChange.bind(this)}
            value={this.state.content}
            value_key="content"
            wysiwyg={true}
            clearOnSubmit={true}
          />
        </div>
        <button className="button dark right mt2">Send Reply</button>
      </form>
    );
  }
}

export default NewReplyForm;
