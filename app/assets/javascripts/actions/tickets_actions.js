import {
  CREATE_REPLY,
  FETCH_TICKETS,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SORT_TICKETS } from '../constants/tickets';
import fetch from 'cross-fetch';

export const createReply = ({ csrf, ...body }) => async (dispatch) => {
  const response = await fetch('/td/messages', {
    body: JSON.stringify(body),
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrf
    },
    method: 'POST'
  });

  const message = await response.json();
  const notificationBody = {
    sender_id: body.sender_id,
    message_id: message.id
  };

  await fetch('/tickets/notify', {
    body: JSON.stringify(notificationBody),
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrf
    },
    method: 'POST'
  });

  dispatch({ type: CREATE_REPLY });
};

export const fetchTickets = () => async (dispatch) => {
  dispatch({ type: FETCH_TICKETS });

  const response = await fetch('/td/tickets');
  const json = await response.json();

  dispatch({ type: RECEIVE_TICKETS, data: json.tickets });
};

export const selectTicket = ticket => ({ type: SELECT_TICKET, ticket });

export const fetchTicket = id => async (dispatch) => {
  const response = await fetch(`/td/tickets/${id}`);
  const data = await response.json();
  dispatch(selectTicket(data.ticket));
};

export const sortTickets = key => ({ type: SORT_TICKETS, key });
