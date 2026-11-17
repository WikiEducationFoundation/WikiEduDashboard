import React from 'react';
import { Link } from 'react-router-dom';
import TicketStatusHandler from './ticket_status_handler';
import TicketOwnerHandler from './ticket_owner_handler';
import { formatDateWithoutTime, formatDateWithTime } from '../../utils/date_utils';
import {
  STUDENT_ROLE, INSTRUCTOR_ROLE, CAMPUS_VOLUNTEER_ROLE, ONLINE_VOLUNTEER_ROLE, STAFF_ROLE
} from '../../constants/user_roles';

const ROLE_LABELS = {
  [STUDENT_ROLE]: 'Student',
  [INSTRUCTOR_ROLE]: 'Instructor',
  [CAMPUS_VOLUNTEER_ROLE]: 'Volunteer',
  [ONLINE_VOLUNTEER_ROLE]: 'Volunteer',
  [STAFF_ROLE]: 'Staff'
};

export const TicketsTableRow = ({ ticket }) => {
  const { sender, sender_email } = ticket;
  const senderName = sender.real_name || sender.username || sender_email || 'Unknown User Record';
  const roleLabel = ROLE_LABELS[sender.course_role];
  const subject = ticket.subject && ticket.subject.replace(/_/g, ' ');

  return (
    <tr className={ticket.status === 0 ? 'table-row--faded' : ''}>
      <td className="sender">
        <span className="clamp" title={senderName}>{senderName}</span>
        {roleLabel && <span className="sender-role">{roleLabel}</span>}
      </td>
      <td className="subject">
        <span className="clamp" title={subject}>{subject}</span>
      </td>
      <td className="course-page">
        {
          ticket.project.id
          ? (
            <Link className="clamp" title={ticket.project.title} to={`/courses/${ticket.project.slug}`}>
              {ticket.project.title}
            </Link>
          )
          : 'Course Unknown'
        }
      </td>
      <td className="created-at">
        <time dateTime={ticket.created_at} title={formatDateWithTime(ticket.created_at)}>
          {formatDateWithoutTime(ticket.created_at)}
        </time>
      </td>
      <td className="status">
        <TicketStatusHandler ticket={ticket} compact />
      </td>
      <td className="owner desktop-only-tc">
        <TicketOwnerHandler ticket={ticket} compact />
      </td>
      <td className="actions">
        <Link className="button" to={`/tickets/dashboard/${ticket.id}`}>Show</Link>
      </td>
    </tr>
  );
};

export default TicketsTableRow;
