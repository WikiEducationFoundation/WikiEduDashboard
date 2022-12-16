import React from 'react';
import { connect } from 'react-redux';
import MultiSelectField from '../common/multi_select_field.jsx';

import { setTicketOwnersFilter } from '../../actions/tickets_actions';

export const TicketOwnersFilter = ({ admins, setOwnersFilter, ownerFilters, disabled }) => {
  const options = admins.map(([username, id]) => ({ label: username, value: id }));
  options.push({ label: 'unassigned', value: null });

  return (
    <MultiSelectField
      options={options}
      label="Filter by owner"
      selected={ownerFilters}
      setSelectedFilters={setOwnersFilter}
      disabled={disabled}
    />
  );
};

const mapStateToProps = ({ admins, tickets }) => ({
  admins,
  ownerFilters: tickets.filters.owners
});

const mapDispatchToProps = {
  setOwnersFilter: setTicketOwnersFilter
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketOwnersFilter);
