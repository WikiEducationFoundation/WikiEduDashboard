import React from 'react';

import Reply from './reply';
import Sidebar from './sidebar';
import NewReplyForm from './new_reply_form';

export const TicketShow = ({
  createReply,
  deleteTicket,
  currentUser,
  fetchTicket,
  ticket,
}) => {
  const createdAt = ticket.messages[0].created_at;
  const replies = ticket.messages.map(message => <Reply key={message.id} message={message} />);

  return (
    <main className="container ticket-dashboard">
      <h1 className="mt4">Ticket from {ticket.sender && (ticket.sender.real_name || ticket.sender.username)}</h1>
      <hr/>
      <section className="messages">
        {replies}
        <NewReplyForm
          ticket={ticket}
          createReply={createReply}
          currentUser={currentUser}
          fetchTicket={fetchTicket}
        />
      </section>
      <Sidebar
        createdAt={createdAt}
        currentUser={currentUser}
        deleteTicket={deleteTicket}
        ticket={ticket}
      />
    </main>
  );
};

export default TicketShow;
