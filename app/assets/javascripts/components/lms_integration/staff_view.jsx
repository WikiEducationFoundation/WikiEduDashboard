import React from 'react';
import PropTypes from 'prop-types';
import { formatDistanceToNow } from 'date-fns';
import { toDate } from '../../utils/date_utils';

// Sidebar variant shown to course instructors and to site admins. Both
// see roster/grade sync metadata and a synced-students count. Only
// course instructors get a clickable link to the LMS course view
// (admins typically don't have access to the LMS instance, so the
// controller omits `course_url` from their payload).
const StaffView = ({ status }) => {
  const courseTitle = status.course_url
    ? <a href={status.course_url} target="_blank" rel="noopener noreferrer">{status.course_title}</a>
    : status.course_title;

  return (
    <div className="module lms-integration-status">
      <h3>{I18n.t('lms_integration.heading', { lms_name: status.lms_name })}</h3>
      <p>
        <strong>{I18n.t('lms_integration.linked_to')}</strong>
        {' '}
        {courseTitle}
      </p>
      <p>
        <strong>{I18n.t('lms_integration.last_sync')}</strong>
        {' '}
        {formatTimestamp(status.last_sync_at)}
      </p>
      {status.last_roster_sync_error && (
        <p className="lms-integration-status__error">
          <strong>{I18n.t('lms_integration.last_roster_sync_error')}</strong>
          {' '}
          {status.last_roster_sync_error}
        </p>
      )}
      {status.last_sync_error && (
        <p className="lms-integration-status__error">
          <strong>{I18n.t('lms_integration.last_sync_error')}</strong>
          {' '}
          {status.last_sync_error}
        </p>
      )}
      {/* Roster size and connected accounts are separate numbers: a full roster
          with nobody connected yet is the normal state early in a term, and
          reporting only the latter made a working roster sync look like it had
          found no students. */}
      <p>
        <strong>{I18n.t('lms_integration.roster_students')}</strong>
        {' '}
        {status.roster_students_count}
      </p>
      <p>
        <strong>{I18n.t('lms_integration.connected_accounts')}</strong>
        {' '}
        {status.connected_accounts_count}
      </p>
    </div>
  );
};

const formatTimestamp = (iso) => {
  if (!iso) return I18n.t('lms_integration.never_synced');
  return formatDistanceToNow(toDate(iso), { addSuffix: true });
};

StaffView.propTypes = {
  status: PropTypes.shape({
    lms_name: PropTypes.string,
    course_title: PropTypes.string,
    course_url: PropTypes.string,
    last_sync_at: PropTypes.string,
    // Recorded exception class + message from the last failed sync of each
    // kind (null when the last run succeeded); rendered verbatim for staff.
    last_roster_sync_error: PropTypes.string,
    last_sync_error: PropTypes.string,
    roster_students_count: PropTypes.number,
    connected_accounts_count: PropTypes.number
  }).isRequired
};

export default StaffView;
