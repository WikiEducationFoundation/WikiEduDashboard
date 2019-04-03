import {
  FETCH_TICKETS,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SORT_TICKETS } from '../constants/tickets';
import { sortByKey } from '../utils/model_utils';

const initialState = {
  all: [],
  byId: {},
  selected: {},
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

export default function (state = initialState, action) {
  switch (action.type) {
    case FETCH_TICKETS:
      return { ...state, loading: true };
    case RECEIVE_TICKETS: {
      const tickets = action.data;
      const byId = tickets.reduce((acc, ticket) => ({ ...acc, [ticket.id]: ticket }), {});

      return {
        ...state,
        all: action.data,
        byId
      };
    }
    case SELECT_TICKET:
      return {
        ...state,
        selected: action.ticket
      };
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
