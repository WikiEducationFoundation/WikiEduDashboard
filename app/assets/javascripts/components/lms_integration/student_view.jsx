import React from 'react';
import PropTypes from 'prop-types';
import { formatDistanceToNow } from 'date-fns';
import { toDate } from '../../utils/date_utils';

// Sidebar variant shown to students enrolled on the course. Has two
// branches:
//   - my_linked: false — the LMS knows about the student (Canvas roster
//     sync has run), but the student hasn't completed Wikipedia OAuth
//     from inside the LMS yet, so no LtiContext row exists for them.
//     Shows an explanation of how to enable grade sync.
//   - my_linked: true — show the student's most recent grade-push
//     timestamp across all their line items.
const StudentView = ({ status }) => {
  const courseTitle = status.course_url
    ? <a href={status.course_url} target="_blank" rel="noopener noreferrer">{status.course_title}</a>
    : status.course_title;

  return (
    <div className="module lms-integration-status">
      <h3>{I18n.t('lms_integration.heading', { lms_name: status.lms_name, default: '%{lms_name} link' })}</h3>
      <p>
        <strong>{I18n.t('lms_integration.linked_to', { default: 'Course:' })}</strong>
        {' '}
        {courseTitle}
      </p>
      {status.my_linked
        ? <LinkedSyncRow lastSyncAt={status.my_last_sync_at} />
        : <NotYetLinkedHint />}
    </div>
  );
};

const LinkedSyncRow = ({ lastSyncAt }) => (
  <p>
    <strong>{I18n.t('lms_integration.my_last_sync', { default: 'Last sync' })}</strong>
    {' '}
    {lastSyncAt
      ? formatDistanceToNow(toDate(lastSyncAt), { addSuffix: true })
      : I18n.t('lms_integration.no_grades_yet', { default: 'No synced progress yet' })}
  </p>
);

LinkedSyncRow.propTypes = { lastSyncAt: PropTypes.string };

const NotYetLinkedHint = () => (
  <p className="lms-integration-status__hint">
    {I18n.t('lms_integration.not_yet_linked', { default: "Your account hasn't been linked to Canvas for this course." })}
  </p>
);

StudentView.propTypes = {
  status: PropTypes.shape({
    lms_name: PropTypes.string,
    course_title: PropTypes.string,
    course_url: PropTypes.string,
    my_linked: PropTypes.bool,
    my_last_sync_at: PropTypes.string
  }).isRequired
};

export default StudentView;
