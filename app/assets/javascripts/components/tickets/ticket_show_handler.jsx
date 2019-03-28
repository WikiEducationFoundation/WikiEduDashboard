import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import Show from './ticket_show';

import { fetchTickets } from '../../actions/tickets_actions';

export class TicketShow extends React.Component {
  constructor() {
    super();

    this.state = {
      ticket: null,
      loading: true
    };
  }

  componentDidMount() {
    const { match, tickets } = this.props;
    const id = match.params.id;
    if (!tickets.loading) return this._setTicketOnFetch(id);

    this.props.fetchTickets().then(() => {
      setTimeout(() => this._setTicketOnFetch(id), 400);
    });
  }

  _setTicketOnFetch(id) {
    const ticket = this.props.tickets.byId[id];
    this.setState({ ticket, loading: false });
  }

  render() {
    if (this.state.loading) return <Loading />;

    return (
      <Show currentUser={this.props.currentUserFromHtml} ticket={this.state.ticket} />
    );
  }
}

const mapStateToProps = ({ currentUserFromHtml, tickets }) => ({
  currentUserFromHtml,
  tickets
});

const mapDispatchToProps = {
  fetchTickets
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketShow);
