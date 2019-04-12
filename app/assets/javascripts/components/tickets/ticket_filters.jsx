import React from 'react';
import { connect } from 'react-redux';
import MultiSelectField from '../common/multi_select_field.jsx';

import { setTicketFilters } from '../../actions/tickets_actions';

export const TicketFilters = ({ admins, setFilters, filters }) => {
  const options = admins.map(([username, id]) => ({ label: username, value: id }));
  options.push({ label: 'unassigned', value: null });

  return (
    <MultiSelectField
      options={options}
      label="Filter by owner"
      selected={filters}
      setSelectedFilters={setFilters}
    />
  );
};

const mapStateToProps = ({ admins, tickets }) => ({
  admins,
  filters: tickets.filters
});

const mapDispatchToProps = {
  setFilters: setTicketFilters
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketFilters);
