import React from 'react';
import List from '../common/list.jsx';
import Row from './tickets_table_row';

// Open NeedHelpAlert tickets are the highest priority, so they get their own
// table above the rest. When the current filters hide every open one, a note
// says so, with a button to switch to the filters that show them all.
const NeedHelpTickets = ({ tickets, hiddenCount, keys, sortBy, showAll }) => {
  let content;
  if (tickets.length) {
    content = (
      <List
        className="table--expandable table--hoverable"
        elements={tickets.map(ticket => <Row key={ticket.id} ticket={ticket} />)}
        keys={keys}
        sortBy={sortBy}
        sortable={true}
        table_key="tickets"
      />
    );
  } else {
    content = (
      <p className="need-help-tickets__hidden">
        <span>
          {`None of the ${hiddenCount} open priority alerts match current filters.`}
        </span>
        <button type="button" className="button small" onClick={showAll}>
          Show all
        </button>
      </p>
    );
  }

  return (
    <section className="need-help-tickets">
      <h2>Priority alerts</h2>
      {content}
    </section>
  );
};

export default NeedHelpTickets;
