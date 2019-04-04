import React from 'react';
import { Link } from 'react-router-dom';

import { STATUSES } from './util';

const TicketsTableRow = ({ ticket }) => (
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
      { ticket.owner.real_name || ticket.owner.username }
    </td>
    <td>
      <Link className="button" to={`/tickets/dashboard/${ticket.id}`}>Reply</Link>
      <button className="button">Resolve</button>
    </td>
  </tr>
);

export default TicketsTableRow;
