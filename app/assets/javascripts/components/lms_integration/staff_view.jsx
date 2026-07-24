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
      {status.last_sync_error_present && (
        <p className="lms-integration-status__error">
          {I18n.t('lms_integration.last_sync_error')}
        </p>
      )}
      <p>
        <strong>{I18n.t('lms_integration.synced_students')}</strong>
        {' '}
        {status.synced_students_count}
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
    last_sync_error_present: PropTypes.bool,
    synced_students_count: PropTypes.number
  }).isRequired
};

export default StaffView;
