import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import Notifications from '../common/notifications';
import Show from './ticket_show';
import { getTicketsById } from '../../selectors';

import {
  createReply,
  deleteTicket,
  fetchTicket,
  fetchTickets,
  readAllMessages,
  selectTicket } from '../../actions/tickets_actions';

export class TicketShow extends React.Component {
  componentDidMount() {
    const id = this.props.match.params.id;
    const ticket = this.props.ticketsById[id];

    if (ticket) {
      this.props.readAllMessages(ticket);
      return this.props.selectTicket(ticket);
    }

    this.props.fetchTicket(id).then(() => {
      this.props.readAllMessages(this.props.selectedTicket);
    });
  }

  render() {
    if (!this.props.selectedTicket.id) return <Loading />;

    return (
      <div>
        <Notifications />
        <Show
          deleteTicket={this.props.deleteTicket}
          createReply={this.props.createReply}
          currentUser={this.props.currentUserFromHtml}
          fetchTicket={this.props.fetchTicket}
          ticket={this.props.selectedTicket}
        />
      </div>
    );
  }
}

const mapStateToProps = state => ({
  currentUserFromHtml: state.currentUserFromHtml,
  ticketsById: getTicketsById(state),
  selectedTicket: state.tickets.selected
});

const mapDispatchToProps = {
  createReply,
  deleteTicket,
  fetchTicket,
  fetchTickets,
  readAllMessages,
  selectTicket
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketShow);
