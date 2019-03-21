import { FETCH_TICKETS, RECEIVE_TICKETS } from '../constants/tickets';

const initialState = {
  all: [],
  loading: true
};

export default function (state = initialState, action) {
  switch (action.type) {
    case FETCH_TICKETS:
      return { ...state, loading: true };
    case RECEIVE_TICKETS:
      return { all: action.data, loading: false };
    default:
      return state;
  }
}
