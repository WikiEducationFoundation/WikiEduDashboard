import React from 'react';
import {
  getLastUpdateSummary,
  getTotaUpdatesMessage,
  getUpdateLogs,
  nextUpdateExpected
} from '../../utils/statistic_update_info_utils';

const UpdateLogs = ({
  course,
  isNextUpdateAfter,
  nextUpdateMessage,
  futureUpdatesMessage,
  additionalUpdateMessage
}) => {
  const updateLogs = getUpdateLogs(course) || [];
  const hasNoUpdates = updateLogs.length === 0;

  // Per-log calculations
  const failureUpdatesCount = updateLogs.filter(log => log.orphan_lock_failure !== undefined).length;

  const erroredUpdatesCount = updateLogs.filter(log => log.error_count !== undefined && log.error_count > 0).length;

  const lastUpdateSummary = getLastUpdateSummary(course);
  const totalUpdatesMessage = getTotaUpdatesMessage(course);

  const recentUpdatesSummary = I18n.t('metrics.recent_updates_summary', {
    total: updateLogs.length,
    failure_count: failureUpdatesCount,
    error_count: erroredUpdatesCount
  });

  // Handle next update message override
  let displayNextUpdateMessage = nextUpdateMessage;
  if (!isNextUpdateAfter) {
    displayNextUpdateMessage = I18n.t('metrics.late_update', {
      late_update_time: nextUpdateExpected(course)
    });
  }

  return (
    <div className="update-logs-section">
      {hasNoUpdates ? (
        <p>
          {I18n.t('metrics.no_updates_yet', {
            defaultValue: 'No updates for this program yet.'
          })}
        </p>
      ) : (
        <>
          {lastUpdateSummary}
          <ul>
            <li>{recentUpdatesSummary}</li>
            <li>{totalUpdatesMessage}</li>
            <li>{displayNextUpdateMessage}</li>
            <li>
              {futureUpdatesMessage} {additionalUpdateMessage}
            </li>
          </ul>
        </>
      )}
    </div>
  );
};

export default UpdateLogs;
