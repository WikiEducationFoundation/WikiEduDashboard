import {
  CREATE_REPLY,
  DELETE_TICKET,
  FETCH_TICKETS,
  FILTER_TICKETS,
  MESSAGE_KIND_REPLY,
  RECEIVE_TICKETS,
  SELECT_TICKET,
  SET_MESSAGES_TO_READ,
  SORT_TICKETS,
  TICKET_STATUS_OPEN,
  UPDATE_TICKET,
  MESSAGE_KIND_NOTE_DELETE
} from '../constants/tickets';
import { STATUSES } from '../components/tickets/util';
import { API_FAIL } from '../constants/api';
import { ADD_NOTIFICATION } from '../constants';
import request from '../utils/request';
import logErrorMessage from '../utils/log_error_message';

export const notifyOfMessage = body => async (dispatch) => {
  try {
    const response = await request('/tickets/notify_owner', {
      body: JSON.stringify(body),
      method: 'POST'
    });
    if (!response.ok) {
      const json = await response.json();
      dispatch({ type: API_FAIL, data: { statusText: json.message } });
    } else {
      dispatch({
        type: ADD_NOTIFICATION,
        notification: {
          message: 'Email was sent to the owner.',
          type: 'success',
          closable: true
        }
      });
    }
  } catch (error) {
    const message = 'Email could not be sent.';
    dispatch({ type: API_FAIL, data: { statusText: message } });
  }
};

const sendReplyEmail = async (notificationBody, dispatch) => {
  try {
    const response = await request('/tickets/reply', {
      body: JSON.stringify(notificationBody),
      method: 'POST'
    });
    if (!response.ok) throw new Error();
  } catch (error) {
    const message = 'Message was created but email could not be sent.';
    dispatch({ type: API_FAIL, data: { statusText: message } });
  }
};

const createReplyRecord = (body, status) => {
  return request('/td/tickets/replies', {
    body: JSON.stringify({ ...body, read: true, status }),
    method: 'POST'
  })
  .then(response => response.json());
};

export const createReply = (body, status, bcc_to_salesforce) => async (dispatch) => {
  let notificationBody;
  // Create the new reply record
  try {
    const message = await createReplyRecord(body, status);

    notificationBody = {
      sender_id: body.sender_id,
      message_id: message.id,
      bcc_to_salesforce
    };
  } catch (error) {
    const message = 'Creation of message failed. Please try again.';
    dispatch({ type: API_FAIL, data: { statusText: message } });
  }

  // Send the reply by email
  if (body.kind === MESSAGE_KIND_REPLY) {
    await sendReplyEmail(notificationBody, dispatch);
  }
  dispatch({ type: CREATE_REPLY });
};

export const readAllMessages = ticket => async (dispatch) => {
  const unreadMessages = ticket.messages.some(message => !message.read);
  if (!unreadMessages) return false;

  const response = await request('/td/read_all_messages', {
    body: JSON.stringify({ ticket_id: ticket.id }),
    method: 'PUT'
  });
  const json = await response.json();
  dispatch({ type: SET_MESSAGES_TO_READ, data: json });
};

const fetchSomeTickets = async (dispatch, page, batchSize = 100) => {
  const offset = batchSize * page;
  const response = await request(`/td/tickets?limit=${batchSize}&offset=${offset}`);
  return response.json().then(({ tickets }) => {
    dispatch({ type: RECEIVE_TICKETS, data: tickets });
  });
};

// Fetch as many tickets as possible
export const fetchTickets = () => async (dispatch) => {
  dispatch({ type: FETCH_TICKETS });

  const batches = Array.from({ length: 10 }, (_el, index) => index);
  // Ensures that each promise will run sequentially
  return batches.reduce(async (previousPromise, batch) => {
    await previousPromise;
    return fetchSomeTickets(dispatch, batch);
  }, Promise.resolve());
};

export const selectTicket = ticket => ({ type: SELECT_TICKET, ticket });

export const fetchTicket = id => async (dispatch) => {
  const response = await request(`/td/tickets/${id}`);
  const data = await response.json();
  dispatch(selectTicket(data.ticket));
};

export const sortTickets = key => ({ type: SORT_TICKETS, key });

const updateTicket = async (id, ticket, dispatch) => {
  const response = await request(`/td/tickets/${id}`, {
    body: JSON.stringify(ticket),
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
  await request(`/td/tickets/${id}`, { method: 'DELETE' });
  dispatch({ type: DELETE_TICKET, id });
};


export const deleteNotePromise = async (id) => {
  const response = await request(`/td/tickets/replies/${id}`, {
    method: 'DELETE'
  });
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.json();
    throw new Error(data.message);
  }
  return response.json();
};

export const deleteNote = id => (dispatch) => {
    deleteNotePromise(id)
      .then(() => {
        dispatch({ type: MESSAGE_KIND_NOTE_DELETE, id });
        dispatch({
          type: ADD_NOTIFICATION,
          notification: {
            message: 'Note Deleted Successfully',
            type: 'success',
            closable: true
          }
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })));
};

export const setTicketOwnersFilter = filters => ({ type: FILTER_TICKETS, filters: { owners: filters } });
export const setTicketStatusesFilter = filters => ({ type: FILTER_TICKETS, filters: { statuses: filters } });

export const setInitialTicketFilters = () => (dispatch, getState) => {
  // Open tickets only
  dispatch(setTicketStatusesFilter([{ value: TICKET_STATUS_OPEN, label: STATUSES[TICKET_STATUS_OPEN] }]));

  // Owned by current user, or no one
  const state = getState();
  const currentUserId = state.currentUserFromHtml.id;
  const [label, value] = state.admins.find(([_username, id]) => id === currentUserId);
  const currentUserOption = { label, value };
  const unassignedOption = { label: 'unassigned', value: null };
  dispatch(setTicketOwnersFilter([currentUserOption, unassignedOption]));
};

