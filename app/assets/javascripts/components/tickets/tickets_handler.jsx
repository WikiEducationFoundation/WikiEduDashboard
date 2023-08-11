import React, { useEffect, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';

import Row from './tickets_table_row';
import Pagination from './pagination';
import Loading from '../common/loading';
import List from '../common/list.jsx';
import SearchBar from '../common/search_bar';
import TicketOwnersFilter from './ticket_owners_filter';
import TicketStatusesFilter from './ticket_statuses_filter';
import SearchTypeSelector from './search_type_selector';
import { fetchTickets, sortTickets, setInitialTicketFilters } from '../../actions/tickets_actions';
import { getFilteredTickets } from '../../selectors';

const TicketsHandler = () => {
  const [page, setPage] = useState(0);
  const [mode, setMode] = useState('filter');
  const [searchType, setSearchType] = useState('no_search');
  const [searchText, setSearchText] = useState('');

  const dispatch = useDispatch();
  const tickets = useSelector(state => state.tickets);
  const filteredTickets = useSelector(state => getFilteredTickets(state));

  const searchBarRef = useRef();
  const searchTypeRef = useRef();

  useEffect(() => {
    const searchByCourseParamInURL = getCourseSearchParamInURL();

    if (searchByCourseParamInURL) {
      setSearchType('by_course');
      setSearchText(searchByCourseParamInURL);
      dispatch(fetchTickets({ search: searchByCourseParamInURL, what: ['by_course'] }));
    } else if (!tickets.all.length) {
      dispatch(fetchTickets());
      dispatch(setInitialTicketFilters());
    }
  }, []);

  const getCourseSearchParamInURL = () => {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('search_by_course');
  };

  const doSearch = () => {
    dispatch(fetchTickets({ search: searchBarRef?.current.value, what: [searchType] }));
    setSearchText(searchBarRef?.current.value);
  };

  const changeMode = (e) => {
    setSearchType(e.value);
    setSearchText('');

    if (e.value === 'no_search') {
      setMode('filter');
      dispatch(fetchTickets());
    } else {
      setMode('search');
    }
  };

  const getTickets = () => {
    if (mode === 'filter') {
      return filteredTickets;
    }

    return tickets.all;
  };

  const goToPage = (newPage) => {
    setPage(newPage);
  };

  if (tickets.loading) return <Loading />;

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

  const pagesLength = Math.floor((filteredTickets.length - 1) / TICKETS_PER_PAGE) + 1;
  const elements = getTickets()
    .slice(page * TICKETS_PER_PAGE, page * TICKETS_PER_PAGE + TICKETS_PER_PAGE)
    .map(ticket => <Row key={ticket.id} ticket={ticket} />);

  // Since this is used multiple places (student_list.jsx), we should
  // refactor this a bit.
  if (tickets.sort.key && keys[tickets.sort.key]) {
    const order = (tickets.sort.sortKey) ? 'asc' : 'desc';
    keys[tickets.sort.key].order = order;
  }

  return (
    <main className="container ticket-dashboard">
      <h1 className="mt4">Ticketing Dashboard</h1>
      <div>
        <div>
          <span className="pull-left w10">Status: </span>
          <TicketStatusesFilter disabled={mode === 'search'} />
          <span className="pull-left w10">Owner: </span>
          <TicketOwnersFilter disabled={mode === 'search'} />
        </div>
        <div>
          <SearchTypeSelector
            value={searchType}
            ref={searchTypeRef}
            handleChange={changeMode}
          />
          <SearchBar
            name="tickets_search"
            value={searchText}
            onClickHandler={doSearch} ref={searchBarRef}
            placeholder={I18n.t('tickets.search_bar_placeholder')}
          />
        </div>
      </div>
      <hr />
      <List
        className="table--expandable table--hoverable"
        elements={elements}
        keys={keys}
        sortBy={key => dispatch(sortTickets(key))}
        sortable={true}
        table_key="tickets"
      />
      <Pagination
        currentPage={page}
        goToPage={goToPage}
        length={pagesLength}
      />
    </main>
  );
};

export default (TicketsHandler);
