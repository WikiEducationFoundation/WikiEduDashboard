import { NEED_HELP_ALERT_SUBJECT, TICKET_STATUS_OPEN } from '../../constants/tickets';

// These statuses are connected to the statuses that are set
// in TicketDispenser::Ticket. If you change them here, you
// should change them there.
export const STATUSES = {
  0: 'Open',
  1: 'Awaiting Response',
  2: 'Resolved'
};

export const isOpenNeedHelpTicket = ticket => (
  ticket.subject === NEED_HELP_ALERT_SUBJECT && ticket.status === TICKET_STATUS_OPEN
);
