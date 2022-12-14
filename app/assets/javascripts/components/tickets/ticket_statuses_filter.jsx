import React from 'react';
import { connect } from 'react-redux';
import MultiSelectField from '../common/multi_select_field.jsx';

import { setTicketStatusesFilter } from '../../actions/tickets_actions';
import { STATUSES } from './util';

const options = Object.entries(STATUSES).map(([value, label]) => ({ label, value }));

export const TicketStatusesFilter = ({ setStatusesFilter, statusesFilter, disabled }) => {
  return (
    <MultiSelectField
      options={options}
      label="Filter by status"
      selected={statusesFilter}
      setSelectedFilters={setStatusesFilter}
      disabled={disabled}
    />
  );
};

const mapStateToProps = ({ admins, tickets }) => ({
  admins,
  statusesFilter: tickets.filters.statuses
});

const mapDispatchToProps = {
  setStatusesFilter: setTicketStatusesFilter
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketStatusesFilter);
