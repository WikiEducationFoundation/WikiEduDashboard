import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import Show from './ticket_show';

import {
  createReply,
  fetchTicket,
  fetchTickets,
  selectTicket } from '../../actions/tickets_actions';

export class TicketShow extends React.Component {
  componentDidMount() {
    const { match, tickets } = this.props;
    const id = match.params.id;
    const ticket = tickets.byId[id];
    if (ticket) return this.props.selectTicket(ticket);

    this.props.fetchTicket(id);
  }

  render() {
    if (this.props.tickets.loading) return <Loading />;

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
  selectTicket
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketShow);
