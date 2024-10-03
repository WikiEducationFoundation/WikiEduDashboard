import React from 'react';
import { Link } from 'react-router-dom';
import { STATUSES } from './util';
import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';

export const TicketsTableRow = ({ ticket }) => {
  const { sender, sender_email } = ticket;
  const senderName = sender.real_name || sender.username || sender_email;

  return (
    <tr className={ticket.status === 0 ? 'table-row--faded' : ''}>
      <td className="sender w10">
        {senderName || 'Unknown User Record' }
      </td>
      <td className="subject w20">
        {ticket.subject && ticket.subject.replace(/_/g, ' ')}
      </td>
      <td className="course-page w20">
        {
          ticket.project.id
            ? <Link to={`/courses/${ticket.project.slug}`}>{ ticket.project.title }</Link>
            : 'Course Unknown'
        }
      </td>
      <td className="status w20">
        { STATUSES[ticket.status] }
        <TicketStatusHandler ticket={ticket} />
      </td>
      <td className="owner w20">
        { ticket.owner.username }
        <TicketOwnerHandler ticket={ticket} />
      </td>
      <td className="actions w10">
        <Link className="button" to={`/tickets/dashboard/${ticket.id}`}>Show</Link>
      </td>
    </tr>
  );
};

export default TicketsTableRow;
