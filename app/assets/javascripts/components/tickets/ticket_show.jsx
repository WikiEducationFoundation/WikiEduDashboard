import React from 'react';
import moment from 'moment';

import Reply from './reply';
import Sidebar from './sidebar';
import NewReplyForm from './new_reply_form';

export const TicketShow = ({ ticket, createReply, currentUser, fetchTicket }) => {
  const createdAt = ticket.messages[0].created_at;
  const dateTime = moment(createdAt).format('MMMM DD, hh:mm a');

  const replies = ticket.messages.map(message => <Reply key={message.id} message={message} />);
  return (
    <main className="container ticket-dashboard">
      <h1 className="mt4">Ticket from {ticket.sender}</h1>
      <p>Created At: <time dateTime={dateTime}>{dateTime}</time></p>
      <p>Course: <span className="bold">{ticket.course.title}</span></p>
      <section className="messages">
        {replies}
        <NewReplyForm
          ticket={ticket}
          createReply={createReply}
          currentUser={currentUser}
          fetchTicket={fetchTicket}
        />
      </section>
      <Sidebar ticket={ticket} currentUser={currentUser} createdAt={createdAt} />
    </main>
  );
};

export default TicketShow;
