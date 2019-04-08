import React from 'react';
import { Link } from 'react-router-dom';
import { STATUSES } from './util';
import TicketStatusHandler from './ticket_status_handler';

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
      <td>{ STATUSES[ticket.status] }</td>
      <td>
        { ticket.owner.username }
      </td>
      <td>
        <Link className="button" to={`/tickets/dashboard/${ticket.id}`}>Show</Link>
        <TicketStatusHandler ticket={ticket} />
      </td>
    </tr>
  );
};

export default TicketsTableRow;
