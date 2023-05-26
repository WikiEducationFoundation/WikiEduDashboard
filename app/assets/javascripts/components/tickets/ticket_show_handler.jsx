import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import Notifications from '../common/notifications';
import Show from './ticket_show';
import { getTicketsById } from '../../selectors';
import withRouter from '../util/withRouter';

import {
  createReply,
  deleteTicket,
  fetchTicket,
  fetchTickets,
  notifyOfMessage,
  readAllMessages,
  selectTicket
} from '../../actions/tickets_actions';

export class TicketShowHandler extends React.Component {
  componentDidMount() {
    const id = this.props.router.params.id;
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
    const id = this.props.router.params.id;
    if (!this.props.selectedTicket.id || this.props.selectedTicket.id !== parseInt(id)) return <Loading />;

    return (
      <div>
        <div className="ticket-notifications">
          <Notifications />
        </div>
        <Show
          deleteTicket={this.props.deleteTicket}
          createReply={this.props.createReply}
          currentUser={this.props.currentUserFromHtml}
          fetchTicket={this.props.fetchTicket}
          notifyOfMessage={this.props.notifyOfMessage}
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
  notifyOfMessage,
  readAllMessages,
  selectTicket
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default withRouter(connector(TicketShowHandler));
