import React from 'react';

import TextAreaInput from '../common/text_area_input.jsx';
import TextInput from '../common/text_input.jsx';
import { MESSAGE_KIND_NOTE, MESSAGE_KIND_REPLY, TICKET_STATUS_AWAITING_RESPONSE, TICKET_STATUS_RESOLVED } from '../../constants/tickets';
import { INSTRUCTOR_ROLE } from '../../constants/user_roles';
import {
  createReply,
  fetchTicket,
} from '../../actions/tickets_actions';

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
      cc: '',
      content: '',
      plainText: '',
      sending: false,
      showCC: false,
      bccToSalesforce: false
    };
  }

  componentDidMount() {
    this.setState({
      bccToSalesforce: this.props.ticket.sender.role === INSTRUCTOR_ROLE
    });
  }

  onChange(_key, content) {
    this.setState({
      [_key]: content
    });
  }

  onTextAreaChange(_key, content, _e) {
    this.setState({
      content,
      plainText: content
    });
  }

  onCCClick(e) {
    e.preventDefault();
    this.setState({
      showCC: !this.state.showCC
    });
  }

  onReply(e) {
    this.setState({ sending: true });
    this.onSubmit(e, TICKET_STATUS_AWAITING_RESPONSE, MESSAGE_KIND_REPLY);
  }

  onCreateNote(e) {
    this.setState({ sending: true });
    this.onSubmit(e, this.props.ticket.status, MESSAGE_KIND_NOTE); // Leave status unchanged
  }

  onResolve(e) {
    this.setState({ sending: true });
    this.onSubmit(e, TICKET_STATUS_RESOLVED, MESSAGE_KIND_REPLY);
  }

  onSubmit(e, status, kind) {
    e.preventDefault();
    if (isBlank(this.state.plainText)) return this.setState({ sending: false });

    const { cc, content, bccToSalesforce } = this.state;
    const ccEmails = this._ccEmailsSplit(cc);
    if (!this._ccEmailsAreValid(ccEmails)) return this.setState({ sending: false });
    const { currentUser, ticket } = this.props;
    let body = {
      content,
      kind,
      ticket_id: ticket.id,
      sender_id: currentUser.id,
      read: true
    };

    if (this.state.cc) {
      const details = { cc: ccEmails.map(email => ({ email })) };
      body = { ...body, details };
    }

    this.props.dispatch(createReply(body, status, bccToSalesforce))
      .then(() => this.props.dispatch(fetchTicket(ticket.id)))
      .then(() => this.setState({ cc: '', content: '', sending: false }));
  }

  toggleBcc(e) {
    this.setState({ bccToSalesforce: e.target.checked });
  }

  _ccEmailsSplit(emailString = '') {
    return emailString.split(',')
      .map(email => email.trim())
      .filter(email => email);
  }

  _ccEmailsAreValid(emails) {
    if (!emails.length) return true;
    const regexp = RegExp(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i);
    return emails.every(email => regexp.test(email));
  }

  render() {
    const ticket = this.props.ticket;
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
            onClick={this.onCCClick.bind(this)}
          >
            +
          </button>
          <div className="pull-right">
            <small>
              BCC to Salesforce
              <input
                checked={this.state.bccToSalesforce}
                className="ml1 top2"
                id="bcc"
                name="bcc"
                onChange={this.toggleBcc.bind(this)}
                type="checkbox"
              />
            </small>
          </div>
        </h3>
        {
          this.state.showCC
          && (
            <div className="cc-fields">
              <label>CC:</label>
              <TextInput
                id="cc"
                onChange={this.onChange.bind(this)}
                value={this.state.cc}
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
            onChange={this.onTextAreaChange.bind(this)}
            value={this.state.content}
            value_key="content"
            wysiwyg={true}
          />
        </div>
        <button
          className="button dark margin right mt2"
          disabled={this.state.sending}
          id="reply-resolve"
          onClick={this.onResolve.bind(this)}
          type="submit"
        >
          Send Reply and Resolve Ticket
        </button>
        <button
          className="button dark right mt2"
          disabled={this.state.sending}
          id="reply"
          onClick={this.onReply.bind(this)}
          type="submit"
        >
          Send Reply
        </button>
        <button
          className="button left mt2"
          disabled={this.state.sending}
          id="create-note"
          onClick={this.onCreateNote.bind(this)}
          type="submit"
        >
          Create Note
        </button>
      </form>
    );
  }
}

export default NewReplyForm;
