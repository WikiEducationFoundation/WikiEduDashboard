import {
  CREATE_REPLY,
  DELETE_TICKET,
  FETCH_TICKETS,
  FILTER_TICKETS,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SET_MESSAGES_TO_READ,
  SORT_TICKETS,
  UPDATE_TICKET
} from '../constants/tickets';
import { API_FAIL } from '../constants/api';
import fetch from 'cross-fetch';

const getCsrf = () => document.querySelector("meta[name='csrf-token']").getAttribute('content');

export const createReply = (body, status) => async (dispatch) => {
  let notificationBody;
  try {
    const response = await fetch('/td/tickets/replies', {
      body: JSON.stringify({ ...body, read: true, status }),
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': getCsrf()
      },
      method: 'POST'
    });

    const message = await response.json();
    notificationBody = {
      sender_id: body.sender_id,
      message_id: message.id
    };
  } catch (error) {
    const message = 'Creation of message failed. Please try again.';
    dispatch({ type: API_FAIL, data: { statusText: message } });
  }

  try {
    const response = await fetch('/tickets/notify', {
      body: JSON.stringify(notificationBody),
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': getCsrf()
      },
      method: 'POST'
    });
    if (!response.ok) {
      const json = await response.json();
      dispatch({ type: API_FAIL, data: { statusText: json.message } });
    }
  } catch (error) {
    const message = 'Message was created but email could not be sent.';
    dispatch({ type: API_FAIL, data: { statusText: message } });
  }

  dispatch({ type: CREATE_REPLY });
};

export const readAllMessages = ticket => async (dispatch) => {
  const unreadMessages = ticket.messages.some(message => !message.read);
  if (!unreadMessages) return false;

  const response = await fetch('/td/read_all_messages', {
    body: JSON.stringify({ ticket_id: ticket.id }),
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrf()
    },
    method: 'PUT'
  });
  const json = await response.json();
  dispatch({ type: SET_MESSAGES_TO_READ, data: json });
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

const updateTicket = async (id, ticket, dispatch) => {
  const response = await fetch(`/td/tickets/${id}`, {
    body: JSON.stringify(ticket),
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrf()
    },
    method: 'PATCH'
  });
  const json = await response.json();
  dispatch({ type: UPDATE_TICKET, id, data: json });
};

export const updateTicketStatus = (id, status) => (dispatch) => {
  updateTicket(id, { status }, dispatch);
};

export const updateTicketOwner = (id, owner_id) => (dispatch) => {
  updateTicket(id, { owner_id }, dispatch);
};

export const deleteTicket = id => async (dispatch) => {
  await fetch(`/td/tickets/${id}`, {
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrf()
    },
    method: 'DELETE'
  });

  dispatch({ type: DELETE_TICKET, id });
};

export const setTicketOwnersFilter = filters => ({ type: FILTER_TICKETS, filters: { owners: filters } });
export const setTicketStatusesFilter = filters => ({ type: FILTER_TICKETS, filters: { statuses: filters } });
