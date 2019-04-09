import React from 'react';
import moment from 'moment';
import { Link } from 'react-router-dom';
import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';
import { STATUSES } from './util';

// This is required because the User Profile is not a React page
const goTo = (ticket) => {
  window.location.pathname = `/users/${ticket.sender}`;
};

export const Sidebar = ({ createdAt, currentUser, ticket }) => {
  const assignedTo = ticket.owner.id === currentUser.id ? 'You' : ticket.owner.username;
  const status = STATUSES[ticket.status];

  return (
    <section className="sidebar">
      <section>Created <time className="bold">{moment(createdAt).fromNow()}</time></section>
      <section>
        Ticket is currently <span className={`${status.toLowerCase()} bold`}>{status}</span>
        <TicketStatusHandler ticket={ticket} />
      </section>
      <section>
        Assigned to <span className="bold">{assignedTo}</span>
        <TicketOwnerHandler ticket={ticket} />
      </section>
      <section>
        {
          ticket.project.id
            ? <Link className="button" to={`/courses/${ticket.project.slug}`}>Go to Course</Link>
            : 'Course Unknown'
        }
      </section>
      <section>
        {
          ticket.sender
            ? <a className="button" onClick={() => goTo(ticket)}>Go to User Account</a>
            : 'Unknown User Record'
        }
      </section>
    </section>
  );
};

export default Sidebar;
