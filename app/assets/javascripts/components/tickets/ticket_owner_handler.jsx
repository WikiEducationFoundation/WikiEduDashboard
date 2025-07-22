import React from 'react';
import { connect } from 'react-redux';
import Select from 'react-select';
import selectStyles from '../../styles/select';

import { updateTicketOwner } from '../../actions/tickets_actions';

export const TicketOwnerHandler = ({ updateOwner, ticket, admins, arialabelledby }) => {
  const options = admins.map(([username, id]) => ({ label: username, value: id }));
  options.push({ label: '— none — ', value: null });

  return (
    <Select
      onChange={({ value: ownerId }) => updateOwner(ticket.id, ownerId)}
      options={options}
      styles={{ ...selectStyles, singleValue: null }}
      value={{ label: (ticket.owner && ticket.owner.username) || '— none — ', value: ticket.owner && ticket.owner.id }}
      aria-labelledby={arialabelledby}
    />
  );
};

const mapStateToProps = ({ admins }) => ({
  admins
});

const mapDispatchToProps = {
  updateOwner: updateTicketOwner
};

const connector = connect(mapStateToProps, mapDispatchToProps);
export default connector(TicketOwnerHandler);
