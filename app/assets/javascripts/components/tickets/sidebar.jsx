import React from 'react';
import moment from 'moment';
import { withRouter } from 'react-router';
import { Link } from 'react-router-dom';

import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';
import { STATUSES } from './util';

export class Sidebar extends React.Component {
  // This is required because the User Profile is not a React page
  goTo() {
    window.location.pathname = `/users/${this.props.ticket.sender}`;
  }

  deleteTicket() {
    if (!confirm('Are you sure you want to delete this ticket?')) return;

    this.props.deleteTicket(this.props.ticket.id)
      .then(() => this.props.history.push('/tickets/dashboard'));
  }

  render() {
    const { createdAt, currentUser, ticket } = this.props;
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
              ? <a className="button" onClick={() => this.goTo()}>Go to User Account</a>
              : 'Unknown User Record'
          }
        </section>
        <section>
          <button className="button danger" onClick={() => this.deleteTicket()}>Delete Ticket</button>
        </section>
      </section>
    );
  }
}

export default withRouter(Sidebar);
