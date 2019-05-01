import React from 'react';
import { connect } from 'react-redux';

import Row from './tickets_table_row';
import Pagination from './pagination';
import Loading from '../common/loading';
import List from '../common/list.jsx';
import TicketOwnersFilter from './ticket_owners_filter';
import TicketStatusesFilter from './ticket_statuses_filter';
import { fetchTickets, sortTickets, setInitialTicketFilters } from '../../actions/tickets_actions';
import { getFilteredTickets } from '../../selectors';

export class TicketsHandler extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      page: 0
    };
  }

  componentDidMount() {
    if (!this.props.tickets.all.length) {
      this.props.fetchTickets();
      this.props.setInitialTicketFilters();
    }
  }

  goToPage(page) {
    this.setState({ page });
  }

  render() {
    if (this.props.tickets.loading) return <Loading />;

    const keys = {
      sender: {
        label: 'Sender',
        desktop_only: false,
        sortable: true
      },
      subject: {
        label: 'Subject',
        desktop_only: false,
        sortable: true
      },
      course_title: {
        label: 'Course',
        desktop_only: false,
        sortable: true
      },
      status: {
        label: 'Status',
        desktop_only: false,
        sortable: true
      },
      owner: {
        label: 'Ticket Owner',
        desktop_only: true,
        sortable: true
      },
      actions: {
        label: 'Actions',
        desktop_only: false,
        sortable: false
      }
    };

    const TICKETS_PER_PAGE = 10;

    const elements = this.props.filteredTickets.map(ticket => (
      <Row key={ticket.id} ticket={ticket} />
    )).slice(this.state.page, this.state.page + TICKETS_PER_PAGE);
    const pagesLength = Math.floor(elements.length / TICKETS_PER_PAGE) + 1;

    // Since this is used multiple places (student_list.jsx), we should
    // refactor this a bit.
    if (this.props.tickets.sort.key && keys[this.props.tickets.sort.key]) {
      const order = (this.props.tickets.sort.sortKey) ? 'asc' : 'desc';
      keys[this.props.tickets.sort.key].order = order;
    }

    return (
      <main className="container ticket-dashboard">
        <h1 className="mt4">Ticketing Dashboard</h1>
        <div>
          <span className="pull-left w10">Status: </span>
          <TicketStatusesFilter />
          <span className="pull-left w10">Owner: </span>
          <TicketOwnersFilter />
        </div>
        <hr/>
        <List
          className="table--expandable table--hoverable"
          elements={elements}
          keys={keys}
          sortBy={this.props.sortTickets}
          sortable={true}
          table_key="tickets"
        />
        <Pagination
          currentPage={this.state.page}
          goToPage={this.goToPage.bind(this)}
          length={pagesLength}
        />
      </main>
    );
  }
}

const mapStateToProps = state => ({
  tickets: state.tickets,
  filteredTickets: getFilteredTickets(state)
});

const mapDispatchToProps = {
  fetchTickets,
  sortTickets,
  setInitialTicketFilters
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketsHandler);
