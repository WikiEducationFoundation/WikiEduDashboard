import React from 'react';
import { connect } from 'react-redux';

import Row from './tickets_table_row';
import Loading from '../common/loading';
import List from '../common/list.jsx';

import { fetchTickets, sortTickets } from '../../actions/tickets_actions';

export class TicketsHandler extends React.Component {
  componentDidMount() {
    if (this.props.tickets.loading) {
      this.props.fetchTickets();
    }
  }

  render() {
    if (this.props.tickets.loading) return <Loading />;

    const keys = {
      sender: {
        label: 'Sender',
        desktop_only: false,
        sortable: true,
        order: 'asc'
      },
      course_title: {
        label: 'Course',
        desktop_only: false,
        sortable: true,
        order: 'asc'
      },
      status: {
        label: 'Status',
        desktop_only: false,
        sortable: true,
        order: 'asc'
      },
      owner: {
        label: 'Ticket Owner',
        desktop_only: true,
        sortable: true,
        order: 'asc'
      },
      actions: {
        label: 'Actions',
        desktop_only: false,
        sortable: false,
        order: 'asc'
      }
    };

    const elements = this.props.tickets.all.map(ticket => (
      <Row key={ticket.id} ticket={ticket} />
    ));

    // Since this is used multiple places (student_list.jsx), we should
    // refactor this a bit.
    if (this.props.tickets.sort.key && keys[this.props.tickets.sort.key]) {
      const order = (this.props.tickets.sort.sortKey) ? 'asc' : 'desc';
      keys[this.props.tickets.sort.key].order = order;
    }

    return (
      <main className="container ticket-dashboard">
        <h1 className="mt4">Ticketing Dashboard</h1>
        <hr/>
        <List
          className="table--expandable table--hoverable"
          elements={elements}
          keys={keys}
          sortBy={this.props.sortTickets}
          sortable={true}
        />
      </main>
    );
  }
}

const mapStateToProps = ({ tickets }) => ({
  tickets
});

const mapDispatchToProps = {
  fetchTickets,
  sortTickets
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketsHandler);
