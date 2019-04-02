import React from 'react';
import { Link } from 'react-router-dom';

import { STATUSES } from './util';

const TicketsTableRow = ({ ticket }) => (
  <tr>
    <td>
      { ticket.sender || 'Unknown User Record' }
    </td>
    <td>
      {
        ticket.course.id
        ? <Link to={`/courses/${ticket.course.slug}`}>{ ticket.course.title }</Link>
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
