import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';

import Loading from '../common/loading';
import Notifications from '../common/notifications';
import Show from './ticket_show';
import { getTicketsById } from '../../selectors';

import {
  fetchTicket,
  readAllMessages,
  selectTicket
} from '../../actions/tickets_actions';
import { useParams } from 'react-router-dom';

const TicketShowHandler = (props) => {
  const { id } = useParams();

  const dispatch = useDispatch();

  const ticketsById = useSelector(state => getTicketsById(state));
  const selectedTicket = useSelector(state => state.tickets.selected);

  useEffect(() => {
    const ticket = ticketsById[id];

    if (ticket) {
      dispatch(readAllMessages(ticket));
      return dispatch(selectTicket(ticket));
    }

    dispatch(fetchTicket(id)).then(() => {
      if (selectedTicket.messages) {
        dispatch(readAllMessages(selectedTicket));
      }
    });
  }, [selectedTicket.id]);

  if (!selectedTicket.id || selectedTicket.id !== parseInt(id)) return <Loading />;

  return (
    <div>
      <div className="ticket-notifications">
        <Notifications />
      </div>
      <Show
        deleteTicket={props.deleteTicket}
        createReply={props.createReply}
        fetchTicket={props.fetchTicket}
        notifyOfMessage={props.notifyOfMessage}
        ticket={selectedTicket}
      />
    </div>
  );
};


export default (TicketShowHandler);
