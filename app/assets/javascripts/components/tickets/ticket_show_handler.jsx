import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import Show from './ticket_show';

import {
  createReply,
  fetchTicket,
  fetchTickets,
  readAllMessages,
  selectTicket } from '../../actions/tickets_actions';

export class TicketShow extends React.Component {
  componentDidMount() {
    const id = this.props.match.params.id;
    const ticket = this.props.tickets.byId[id];

    const csrf = document.querySelector("meta[name='csrf-token']").getAttribute('content');
    if (ticket) {
      this.props.readAllMessages(csrf, ticket);
      return this.props.selectTicket(ticket);
    }

    this.props.fetchTicket(id).then(() => {
      this.props.readAllMessages(csrf, this.props.tickets.selected);
    });
  }

  render() {
    if (!this.props.tickets.selected.id) return <Loading />;

    return (
      <Show
        createReply={this.props.createReply}
        currentUser={this.props.currentUserFromHtml}
        fetchTicket={this.props.fetchTicket}
        ticket={this.props.tickets.selected}
      />
    );
  }
}

const mapStateToProps = ({ currentUserFromHtml, tickets }) => ({
  currentUserFromHtml,
  tickets
});

const mapDispatchToProps = {
  createReply,
  fetchTicket,
  fetchTickets,
  readAllMessages,
  selectTicket
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketShow);
