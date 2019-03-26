import React from 'react';
import { connect } from 'react-redux';

import Loading from '../common/loading';
import TicketTable from './tickets_table';

import { fetchTickets } from '../../actions/tickets_actions';

export class TicketsHandler extends React.Component {
  componentDidMount() {
    this.props.fetchTickets();
  }

  render() {
    if (this.props.tickets.loading) return <Loading />;

    return (
      <main className="container">
        <h1 className="mt4">Ticketing Dashboard</h1>
        <hr/>
        <TicketTable tickets={this.props.tickets.all} />
      </main>
    );
  }
}

const mapStateToProps = ({ tickets }) => ({
  tickets
});

const mapDispatchToProps = {
  fetchTickets
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketsHandler);
