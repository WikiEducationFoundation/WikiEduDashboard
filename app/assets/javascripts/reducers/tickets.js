import {
  DELETE_TICKET,
  FETCH_TICKETS,
  FILTER_TICKETS,
  EMPTY_LIST,
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
  actions: true
};

const replaceTicket = (tickets, newTicket) => {
  const ticket = tickets.find(tick => tick.id === newTicket.id);
  const index = tickets.indexOf(ticket);

  return [
    ...tickets.slice(0, index),
    newTicket,
    ...tickets.slice(index + 1)
  ];
};
const removeTicket = (tickets, id) => {
  const ticket = tickets.find(tick => tick.id === id);
  const index = tickets.indexOf(ticket);

  return [
    ...tickets.slice(0, index),
    ...tickets.slice(index + 1)
  ];
};

const removeNote = (notes, id) => {
  const note = notes.find(item => item.id === id);
  const index = notes.indexOf(note);
  return [
    ...notes.slice(0, index),
    ...notes.slice(index + 1)
  ];
};

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
      const all = removeNote(state.selected.messages, action.id);
      state.selected.messages = all;
      return {
        ...state,
        all
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
    case RECEIVE_TICKETS: {
      return {
        ...state,
        all: state.all.concat(action.data),
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
      const selectedId = state.selected.id;
      const all = replaceTicket(state.all, action.data.ticket);
      const selected = selectedId ? all.find(ticket => ticket.id === selectedId) : {};

      return {
        ...state,
        all,
        selected
      };
    }
    default:
      return state;
  }
}
