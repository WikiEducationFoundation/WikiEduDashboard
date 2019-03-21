import React from 'react';

import TicketsTableRow from './tickets_table_row';

const TicketsTable = ({ tickets }) => (
  <table className="table">
    <thead>
      <tr>
        <th>Sender</th>
        <th>Course</th>
        <th>Status</th>
        <th>Assigned To</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      { tickets.map(ticket => <TicketsTableRow key={ticket.id} ticket={ticket} />) }
    </tbody>
  </table>
);

export default TicketsTable;
