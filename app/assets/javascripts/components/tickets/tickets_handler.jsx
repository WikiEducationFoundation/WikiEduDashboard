import React from 'react';
import { connect } from 'react-redux';

import Row from './tickets_table_row';
import Pagination from './pagination';
import Loading from '../common/loading';
import List from '../common/list.jsx';
import SearchBar from '../common/search_bar';
import TicketOwnersFilter from './ticket_owners_filter';
import TicketStatusesFilter from './ticket_statuses_filter';
import SearchTypeSelector from './search_type_selector';
import { fetchTickets, sortTickets, setInitialTicketFilters, emptyList } from '../../actions/tickets_actions';
import { getFilteredTickets } from '../../selectors';

export class TicketsHandler extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      page: 0,
      mode: 'filter',
      searchType: 'no_search'
    };
    this.searchBarRef = React.createRef();
    this.searchTypeRef = React.createRef();
  }

  componentDidMount() {
    if (!this.props.tickets.all.length) {
      this.props.fetchTickets();
      this.props.setInitialTicketFilters();
    }
  }

  doSearch = () => {
    this.props.fetchTickets({ search: this.searchBarRef?.current.value, what: this.state.searchType });
  };

  changeMode = (e) => {
    this.setState({ searchType: e.value });
    if (e.value === 'no_search') {
      this.setState({ mode: 'filter' });
      this.props.fetchTickets();
    } else {
      this.setState({ mode: 'search' });
    }
  };

  getTickets = () => {
    if (this.state.mode === 'filter') {
      return this.props.filteredTickets;
    }

    return this.props.tickets.all;
  };

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

    const pagesLength = Math.floor((this.props.filteredTickets.length - 1) / TICKETS_PER_PAGE) + 1;
    const elements = this.getTickets()
      .slice(this.state.page * TICKETS_PER_PAGE, this.state.page * TICKETS_PER_PAGE + TICKETS_PER_PAGE)
      .map(ticket => <Row key={ticket.id} ticket={ticket} />);

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
          <div>
            <span className="pull-left w10">Status: </span>
            <TicketStatusesFilter disabled={this.state.mode === 'search'}/>
            <span className="pull-left w10">Owner: </span>
            <TicketOwnersFilter disabled={this.state.mode === 'search'}/>
          </div>
          <div>
            <SearchTypeSelector
              value={this.state.searchType}
              ref={this.searchTypeRef}
              handleChange={this.changeMode}
            />
            <SearchBar
              name="tickets_search"
              onClickHandler={this.doSearch} ref={this.searchBarRef}
              placeholder={I18n.t('tickets.search_bar_placeholder')}
            />
          </div>
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
  setInitialTicketFilters,
  emptyList
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketsHandler);
