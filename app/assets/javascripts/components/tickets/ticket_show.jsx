import React from 'react';
import { Link } from 'react-router-dom';
import Reply from './reply';
import Sidebar from './sidebar';
import NewReplyForm from './new_reply_form';
import { useSelector } from 'react-redux';

export const TicketShow = ({
  deleteTicket,
  notifyOfMessage,
  ticket,
}) => {
  const currentUser = useSelector(state => state.currentUserFromHtml);

  const createdAt = ticket.messages[0].created_at;
  const replies = ticket.messages.map(message => <Reply key={message.id} message={message} />);

  return (
    <section className="container ticket-dashboard">
      <h1 className="sr-only">Ticket Details</h1>
      <p className="mt1 back-to-dashboard">
        <Link to="/tickets/dashboard">← Ticketing Dashboard</Link>
      </p>
      <h2 className="title">
        Ticket from {ticket.sender.real_name || ticket.sender.username || ticket.sender_email}
      </h2>
      <hr />
      <section className="messages">
        {replies}
        <NewReplyForm
          ticket={ticket}
          currentUser={currentUser}
        />
      </section>
      <Sidebar
        createdAt={createdAt}
        currentUser={currentUser}
        deleteTicket={deleteTicket}
        notifyOfMessage={notifyOfMessage}
        ticket={ticket}
      />
    </section>
  );
};

export default TicketShow;
