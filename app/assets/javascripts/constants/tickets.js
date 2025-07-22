export const CREATE_REPLY = 'CREATE_REPLY';
export const DELETE_TICKET = 'DELETE_TICKET';
export const FETCH_TICKETS = 'FETCH_TICKETS';
export const EMPTY_LIST = 'EMPTY_LIST';
export const RECEIVE_TICKETS = 'RECEIVE_TICKETS';
export const SELECT_TICKET = 'SELECT_TICKET';
export const SET_MESSAGES_TO_READ = 'SET_MESSAGES_TO_READ';
export const SORT_TICKETS = 'SORT_TICKETS';
export const UPDATE_TICKET = 'UPDATE_TICKET';
export const FILTER_TICKETS = 'FILTER_TICKETS';

// These statuses are connected to the statuses that are set
// in TicketDispenser::Ticket. If you change them here, you
// should change them there.
export const TICKET_STATUS_OPEN = 0;
export const TICKET_STATUS_AWAITING_RESPONSE = 1;
export const TICKET_STATUS_RESOLVED = 2;

export const MESSAGE_KIND_REPLY = 0;
export const MESSAGE_KIND_NOTE = 1;

export const MESSAGE_KIND_NOTE_DELETE = 'MESSAGE_KIND_NOTE_DELETE';
