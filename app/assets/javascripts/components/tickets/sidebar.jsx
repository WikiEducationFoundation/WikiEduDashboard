import React from 'react';
import { useNavigate, Link } from 'react-router-dom';
import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';
import { STATUSES } from './util';
import { toDate } from '../../utils/date_utils';
import { formatDistanceToNow } from 'date-fns';

const Sidebar = ({ createdAt, currentUser, deleteTicket, notifyOfMessage, ticket }) => {
  const navigate = useNavigate();

  const notifyOwner = () => {
    notifyOfMessage({
      message_id: ticket.messages[ticket.messages.length - 1].id,
      sender_id: currentUser.id
    });
  };

  const deleteSelectedTicket = () => {
    if (!confirm('Are you sure you want to delete this ticket?')) return;

    deleteTicket(ticket.id)
      .then(() => navigate('/tickets/dashboard'));
  };
  const assignedTo = ticket.owner.id === currentUser.id ? 'You' : ticket.owner.username;
  const status = STATUSES[ticket.status];
  const realName = ticket.sender.real_name ? `(${ticket.sender.real_name})` : '';

  return (
    <section className="sidebar">
      <section className="created-at">Created <time className="bold">{formatDistanceToNow(toDate(createdAt), { addSuffix: true })}</time></section>
      <section className="status">
        Ticket is currently <span className={`${status.toLowerCase()} bold`}>{status}</span>
        <TicketStatusHandler ticket={ticket} />
      </section>
      <section className="owner">
        Assigned to <span className="bold">{assignedTo}</span>
        <TicketOwnerHandler ticket={ticket} />
      </section>
      <section className="course-name">
        {
          ticket.project.id
            ? <Link target="_blank" to={`/courses/${ticket.project.slug}`}>Course page: {ticket.project.title}</Link>
            : 'Course Unknown'
        }
      </section>
      <section className="related-tickets">
        <Link target="_blank" to={`/tickets/dashboard?search_by_course=${ticket.project.slug}`}>
          Search all tickets for: {ticket.project.title}
        </Link>
      </section>
      <section className="course-user-details">
        {
          ticket.project.id && ticket.sender.username
            ? <Link target="_blank" to={`/courses/${ticket.project.slug}/students/articles/${ticket.sender.username}`}>User assignments: {ticket.sender.username}</Link>
            : ''
        }
      </section>
      <section className="user-record">
        {
          ticket.sender.username
            ? <a target="_blank" href={`/users/${ticket.sender.username}`}>Profile: {`${ticket.sender.username} ${realName}`}</a>
            : 'Unknown User Record'
        }
      </section>
      <section>
        <button className="button info" onClick={() => notifyOwner()}>Email Ticket Owner</button>
      </section>
      <section>
        <button className="button danger" onClick={() => deleteSelectedTicket()}>Delete Ticket</button>
      </section>
    </section>
  );
};

export default (Sidebar);
