import {
  FETCH_TICKETS,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SET_MESSAGES_TO_READ,
  SORT_TICKETS,
  UPDATE_TICKET
} from '../constants/tickets';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  all: [],
  byId: {},
  selected: {},
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

const byIdFromAll = tickets => tickets.reduce((acc, ticket) => ({ ...acc, [ticket.id]: ticket }), {});
const replaceTicket = (tickets, newTicket) => {
  const ticket = tickets.find(tick => tick.id === newTicket.id);
  const index = tickets.indexOf(ticket);

  return [
    ...tickets.slice(0, index),
    newTicket,
    ...tickets.slice(index + 1)
  ];
};

export default function (state = initialState, action) {
  switch (action.type) {
    case FETCH_TICKETS:
      return { ...state, loading: true };
    case RECEIVE_TICKETS: {
      const tickets = action.data;
      const byId = byIdFromAll(tickets);

      return {
        ...state,
        all: action.data,
        loading: false,
        byId
      };
    }
    case SELECT_TICKET:
      return {
        ...state,
        selected: action.ticket
      };
    case SET_MESSAGES_TO_READ: {
      const all = replaceTicket(state.all, action.data.ticket);
      const byId = byIdFromAll(all);

      return {
        ...state,
        all,
        byId,
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
      const byId = byIdFromAll(all);
      const selected = byId[selectedId];

      return {
        ...state,
        all,
        byId,
        selected
      };
    }
    default:
      return state;
  }
}
