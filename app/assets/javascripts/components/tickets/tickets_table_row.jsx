import React from 'react';
import { Link } from 'react-router-dom';

const STATUSES = [
  'Open',
  'Waiting Response',
  'Resolved'
];

const TicketsTableRow = ({ ticket }) => (
  <tr>
    <td>
      { ticket.sender }
    </td>
    <td>
      <Link to={`/courses/${ticket.course.slug}`}>{ ticket.course.title }</Link>
    </td>
    <td>{ STATUSES[ticket.status] }</td>
    <td>
      { ticket.owner.real_name }
    </td>
    <td>
      <button className="button">Read</button>
      <button className="button">Resolve</button>
    </td>
  </tr>
);

export default TicketsTableRow;
