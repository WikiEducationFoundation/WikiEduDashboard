import { FETCH_TICKETS, RECEIVE_TICKETS } from '../constants/tickets';
import fetch from 'cross-fetch';

export const fetchTickets = () => async (dispatch) => {
  dispatch({ type: FETCH_TICKETS });

  const response = await fetch('/tickets');
  const json = await response.json();

  dispatch({ type: RECEIVE_TICKETS, data: json.tickets });
};
