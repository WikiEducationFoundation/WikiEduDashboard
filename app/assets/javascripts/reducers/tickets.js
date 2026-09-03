import {
  DELETE_TICKET,
  FETCH_TICKETS,
  FILTER_TICKETS,
  EMPTY_LIST,
  RECEIVE_TICKET,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SET_MESSAGES_TO_READ,
  SORT_TICKETS,
  UPDATE_TICKET,
  MESSAGE_KIND_NOTE_DELETE
} from '../constants/tickets';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  all: [],
  selected: {},
  filters: {
    owners: [],
    statuses: [],
    search: ''
  },
  loading: true,
  sort: {
    sortKey: null,
    key: null
  }
};

const SORT_DESCENDING = {
  sender: true,
  course_title: true,
  status: true,
  owner: true,
  actions: true,
  updated_at: true
};

// `all` is the ticket index list, and it is only ever populated by RECEIVE_TICKETS.
// Single-ticket updates must never insert into it: TicketsHandler treats a
// non-empty list as "already loaded" and skips fetching, so a ticket that sneaks
// in while `loading` is still true leaves the index spinning forever.
const replaceTicket = (tickets, newTicket) => {
  const index = tickets.findIndex(tick => tick.id === newTicket.id);
  if (index === -1) return tickets;

  return [
    ...tickets.slice(0, index),
    newTicket,
    ...tickets.slice(index + 1)
  ];
};

const removeTicket = (tickets, id) => tickets.filter(ticket => ticket.id !== id);

export default function (state = initialState, action) {
  switch (action.type) {
    case DELETE_TICKET: {
      const all = removeTicket(state.all, action.id);
      return {
        ...state,
        all,
        loading: false
      };
    }
    case MESSAGE_KIND_NOTE_DELETE: {
      const messages = state.selected.messages.filter(message => message.id !== action.id);
      const selected = { ...state.selected, messages };
      return {
        ...state,
        all: replaceTicket(state.all, selected),
        selected
      };
    }
    case FETCH_TICKETS:
      return { ...state, all: [], loading: true };
    case FILTER_TICKETS: {
      const newFilters = { ...state.filters, ...action.filters };
      return { ...state, filters: newFilters };
    }
    case EMPTY_LIST: {
      return {
        ...state,
        all: []
      };
    }
    case RECEIVE_TICKET: {
      // A freshly fetched ticket is the newest version we have, so it also
      // refreshes the index row (e.g. the status after a reply resolves it).
      return {
        ...state,
        all: replaceTicket(state.all, action.ticket),
        selected: action.ticket
      };
    }
    case RECEIVE_TICKETS: {
      const allTickets = state.all.concat(action.data);
      const sorted = sortByKey(allTickets, 'updated_at', null, true).newModels; // Show recently updated tickets first.
      return {
        ...state,
        all: sorted,
        loading: false
      };
    }
    case SELECT_TICKET:
      return {
        ...state,
        selected: action.ticket
      };
    case SET_MESSAGES_TO_READ: {
      const all = replaceTicket(state.all, action.data.ticket);
      return {
        ...state,
        all,
        selected: { ...action.data.ticket }
      };
    }
    case SORT_TICKETS: {
      const sorted = sortByKey(state.all, action.key, state.sort.sortKey, SORT_DESCENDING[action.key]);

      return {
        ...state,
        all: sorted.newModels,
        sort: {
          sortKey: sorted.newKey,
          key: action.key
        }
      };
    }
    case UPDATE_TICKET: {
      const updated = action.data.ticket;
      const selected = state.selected.id === updated.id ? updated : state.selected;

      return {
        ...state,
        all: replaceTicket(state.all, updated),
        selected
      };
    }
    default:
      return state;
  }
}
