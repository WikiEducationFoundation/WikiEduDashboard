import React from 'react';
import withRouter from '../util/withRouter';
import { Link } from 'react-router-dom';

import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';
import { STATUSES } from './util';
import { toDate } from '../../utils/date_utils';
import { formatDistanceToNow } from 'date-fns';

export class Sidebar extends React.Component {
  notifyOwner() {
    const { currentUser, ticket } = this.props;
    this.props.notifyOfMessage({
      message_id: ticket.messages[ticket.messages.length - 1].id,
      sender_id: currentUser.id
    });
  }

  deleteTicket() {
    if (!confirm('Are you sure you want to delete this ticket?')) return;

    this.props.deleteTicket(this.props.ticket.id)
      .then(() => this.props.router.navigate('/tickets/dashboard'));
  }

  render() {
    const { createdAt, currentUser, ticket } = this.props;
    const assignedTo = ticket.owner.id === currentUser.id ? 'You' : ticket.owner.username;
    const status = STATUSES[ticket.status];
    const realName = ticket.sender.real_name ? `(${ticket.sender.real_name})` : '';

    return (
      <section className="sidebar">
        <section className="created-at">Created <time className="bold">{formatDistanceToNow(toDate(createdAt))}</time></section>
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
              ? <a target="_blank" href={`/users/${this.props.ticket.sender.username}`}>Profile: {`${ticket.sender.username} ${realName}`}</a>
              : 'Unknown User Record'
          }
        </section>
        <section>
          <button className="button info" onClick={() => this.notifyOwner()}>Email Ticket Owner</button>
        </section>
        <section>
          <button className="button danger" onClick={() => this.deleteTicket()}>Delete Ticket</button>
        </section>
      </section>
    );
  }
}

export default withRouter(Sidebar);
