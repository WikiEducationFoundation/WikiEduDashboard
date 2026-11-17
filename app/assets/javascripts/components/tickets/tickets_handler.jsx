import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';

import Row from './tickets_table_row';
import Pagination from './pagination';
import Loading from '../common/loading';
import List from '../common/list.jsx';
import TicketOwnersFilter from './ticket_owners_filter';
import TicketStatusesFilter from './ticket_statuses_filter';
import NeedHelpTickets from './need_help_tickets';
import { isOpenNeedHelpTicket } from './util';
import { fetchTickets, sortTickets, setInitialTicketFilters, showAllOpenTickets } from '../../actions/tickets_actions';
import { getFilteredTickets, getOpenNeedHelpTickets } from '../../selectors';

const TicketsHandler = () => {
  const [page, setPage] = useState(0);
  const [mode, setMode] = useState('filter');
  const [searchQuery, setSearchQuery] = useState({ by_email_or_username: '', in_subject: '', in_content: '', by_course: '', });

  const dispatch = useDispatch();
  const tickets = useSelector(state => state.tickets);
  const filteredTickets = useSelector(state => getFilteredTickets(state));
  const openNeedHelpTickets = useSelector(state => getOpenNeedHelpTickets(state));

  useEffect(() => {
    const searchByCourseParamInURL = getCourseSearchParamInURL();

    if (searchByCourseParamInURL) {
      setSearchQuery(prevState => ({ ...prevState, by_course: searchByCourseParamInURL }));
      dispatch(fetchTickets(searchQuery));
    } else if (!tickets.all.length) {
      dispatch(fetchTickets());
      dispatch(setInitialTicketFilters());
    }
  }, []);

  const getCourseSearchParamInURL = () => {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('search_by_course');
  };

  const updateSearchQuery = (e, queryKey) => {
    setSearchQuery(prevState => ({ ...prevState, [queryKey]: e.target.value }));
  };

  const doSearch = () => {
    setMode('search');
    dispatch(fetchTickets(searchQuery));
  };

  const clearSearch = () => {
    setMode('filter');
    setSearchQuery({ by_email_or_username: '', in_subject: '', in_content: '', by_course: '', });
    dispatch(fetchTickets());
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

  const showAllOpenNeedHelpTickets = () => {
    setPage(0);
    dispatch(showAllOpenTickets());
  };

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
    created_at: {
      label: 'Created',
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

  const isEmptySearch = Object.values(searchQuery).every(val => val === '');

  const listedTickets = getTickets();
  const needHelpTickets = listedTickets.filter(isOpenNeedHelpTicket);
  const otherTickets = listedTickets.filter(ticket => !isOpenNeedHelpTicket(ticket));
  // Search results are not filtered, so the table shows only when the results
  // include an open NeedHelpAlert. Otherwise, it shows whenever any are open.
  const showNeedHelpTickets = mode === 'search'
    ? needHelpTickets.length > 0
    : openNeedHelpTickets.length > 0;

  const pagesLength = Math.floor((otherTickets.length - 1) / TICKETS_PER_PAGE) + 1;
  const elements = otherTickets
    .slice(page * TICKETS_PER_PAGE, page * TICKETS_PER_PAGE + TICKETS_PER_PAGE)
    .map(ticket => <Row key={ticket.id} ticket={ticket} />);

  // Since this is used multiple places (student_list.jsx), we should
  // refactor this a bit.
  if (tickets.sort.key && keys[tickets.sort.key]) {
    const order = (tickets.sort.sortKey) ? 'asc' : 'desc';
    keys[tickets.sort.key].order = order;
  }

  return (
    <section className="container ticket-dashboard">
      <h1 className="mt4">Ticketing Dashboard</h1>
      <div>
        <div>
          <span className="pull-left w10">Status: </span>
          <TicketStatusesFilter disabled={mode === 'search'} />
          <span className="pull-left w10">Owner: </span>
          <TicketOwnersFilter disabled={mode === 'search'} />
        </div>
        <div style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: '5px',
          marginTop: '5px'
        }}
        >
          <input
            type="text"
            name="tickets_search_email_or_username"
            value={searchQuery.by_email_or_username}
            onChange={e => updateSearchQuery(e, 'by_email_or_username')}
            placeholder="Search by email or username"
          />
          <input
            type="text"
            name="tickets_search_subject"
            value={searchQuery.in_subject}
            onChange={e => updateSearchQuery(e, 'in_subject')}
            placeholder="Search by subject"
          />
          <input
            type="text"
            name="tickets_search_content"
            value={searchQuery.in_content}
            onChange={e => updateSearchQuery(e, 'in_content')}
            placeholder="Search by content"
          />
          <input
            type="text"
            name="tickets_search_course"
            value={searchQuery.by_course}
            onChange={e => updateSearchQuery(e, 'by_course')}
            placeholder="Search by course"
          />
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 10 }}>
          <button
            type="button"
            onClick={doSearch}
            className="button dark"
            name="search_tickets"
            disabled={isEmptySearch}
          >
            {I18n.t('tickets.search_bar_placeholder')}
          </button>
          <button
            type="button"
            onClick={clearSearch}
            className="button"
            name="clear_search"
          >
            Clear search
          </button>
        </div>
      </div>
      <hr />
      {
        tickets.loading
          ? <Loading />
          : (
            <>
              {showNeedHelpTickets && (
                <NeedHelpTickets
                  tickets={needHelpTickets}
                  hiddenCount={openNeedHelpTickets.length}
                  keys={keys}
                  sortBy={key => dispatch(sortTickets(key))}
                  showAll={showAllOpenNeedHelpTickets}
                />
              )}
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
            </>
          )
      }
    </section>
  );
};

export default (TicketsHandler);
