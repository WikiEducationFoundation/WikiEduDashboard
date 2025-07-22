import React from 'react';
import { connect } from 'react-redux';
import Select from 'react-select';
import selectStyles from '../../styles/select';
import { STATUSES } from './util';

import { updateTicketStatus } from '../../actions/tickets_actions';

export const TicketStatusHandler = ({ updateStatus, ticket, arialabelledby }) => {
  const options = Object.entries(STATUSES).map(([value, label]) => ({ label, value }));
  return (
    <Select
      onChange={({ value: status }) => updateStatus(ticket.id, status)}
      options={options}
      styles={{ ...selectStyles, singleValue: null }}
      value={{ label: STATUSES[ticket.status], value: ticket.status }}
      aria-labelledby={arialabelledby}
    />
  );
};

const mapDispatchToProps = {
  updateStatus: updateTicketStatus
};

const connector = connect(null, mapDispatchToProps);
export default connector(TicketStatusHandler);
