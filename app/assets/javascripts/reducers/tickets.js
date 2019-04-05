import {
  FETCH_TICKETS,
  RECEIVE_TICKETS,
  RESOLVE_TICKET,
  SELECT_TICKET,
  SET_MESSAGES_TO_READ,
  SORT_TICKETS } from '../constants/tickets';
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
    case RESOLVE_TICKET: {
      const ticket = state.all.find(tick => tick.id === action.id);
      ticket.status = TICKET_STATUS_RESOLVED;
      const byId = byIdFromAll(state.all);
      return {
        ...state,
        byId
      };
    }
    case SELECT_TICKET:
      return {
        ...state,
        selected: action.ticket
      };
    case SET_MESSAGES_TO_READ: {
      state.selected.read = true;

      const id = action.data;
      const ticket = state.all.find(tick => tick.id === id);
      ticket.read = true;

      return {
        ...state,
        selected: { ...state.selected }
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
    default:
      return state;
  }
}
