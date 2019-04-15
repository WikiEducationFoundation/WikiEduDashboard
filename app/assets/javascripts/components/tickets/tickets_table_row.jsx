import React from 'react';
import { Link } from 'react-router-dom';
import { STATUSES } from './util';
import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';

const TicketsTableRow = ({ ticket }) => {
  return (
    <tr className={ticket.status === 0 ? 'table-row--faded' : ''}>
      <td className="w15">
        {ticket.sender.real_name || ticket.sender.username || 'Unknown User Record' }
      </td>
      <td className="w30">
        {
          ticket.project.id
          ? <Link to={`/courses/${ticket.project.slug}`}>{ ticket.project.title }</Link>
          : 'Course Unknown'
        }
      </td>
      <td className="w20">
        { STATUSES[ticket.status] }
        <TicketStatusHandler ticket={ticket} />
      </td>
      <td className="w20">
        { ticket.owner.username }
        <TicketOwnerHandler ticket={ticket} />
      </td>
      <td className="w10">
        <Link className="button" to={`/tickets/dashboard/${ticket.id}`}>Show</Link>
      </td>
    </tr>
  );
};

export default TicketsTableRow;
