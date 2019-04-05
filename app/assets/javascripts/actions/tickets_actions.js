import {
  CREATE_REPLY,
  FETCH_TICKETS,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SET_MESSAGES_TO_READ,
  SORT_TICKETS } from '../constants/tickets';
import fetch from 'cross-fetch';

export const createReply = (body, csrf, status) => async (dispatch) => {
  console.log(body);
  console.log(csrf);
  console.log(status);
  const response = await fetch(`/td/tickets/${body.ticket_id}`, {
    body: JSON.stringify({ ...body, read: true, status }),
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrf
    },
    method: 'PATCH'
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

export const readAllMessages = (csrf, ticket) => async (dispatch) => {
  const unreadMessages = ticket.messages.some(message => !message.read);
  if (!unreadMessages) return false;

  const response = await fetch('/td/read_all_messages', {
    body: JSON.stringify({ ticket_id: ticket.id }),
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrf
    },
    method: 'PUT'
  });
  await response.json();

  dispatch({ type: SET_MESSAGES_TO_READ, data: ticket.id });
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
