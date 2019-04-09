import React from 'react';
import { Link } from 'react-router-dom';
import { STATUSES } from './util';
import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';

const TicketsTableRow = ({ ticket }) => {
  return (
    <tr className={ticket.read ? 'table-row--faded' : 'read'}>
      <td>
        { ticket.sender || 'Unknown User Record' }
      </td>
      <td>
        {
          ticket.project.id
          ? <Link to={`/courses/${ticket.project.slug}`}>{ ticket.project.title }</Link>
          : 'Course Unknown'
        }
      </td>
      <td>
        { STATUSES[ticket.status] }
        <TicketStatusHandler ticket={ticket} />
      </td>
      <td>
        { ticket.owner.username }
        <TicketOwnerHandler ticket={ticket} />
      </td>
      <td>
        <Link className="button" to={`/tickets/dashboard/${ticket.id}`}>Show</Link>
      </td>
    </tr>
  );
};

export default TicketsTableRow;
