import React from 'react';
import { getLastUpdateSummary, getTotaUpdatesMessage } from '../../utils/statistic_update_info_utils';

const UpdateLogs = ({ course, updateLogs, isNextUpdateAfter, nextUpdateMessage }) => {
  const hasNoUpdates = updateLogs.length === 0;
  const lastUpdateSummary = getLastUpdateSummary(course);
  const totalUpdatesMessage = getTotaUpdatesMessage(course);

  const failureUpdatesCount = updateLogs.filter(
    log => log.orphan_lock_failure !== undefined
  ).length;

  const erroredUpdatesCount = updateLogs.filter(
    log => log.error_count !== undefined && log.error_count > 0
  ).length;

  const recentUpdatesSummary = I18n.t('metrics.recent_updates_summary', {
    total: updateLogs.length,
    failure_count: failureUpdatesCount,
    error_count: erroredUpdatesCount
  });

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
            <li>{nextUpdateMessage}</li>
          </ul>
        </>
      )}
    </div>
  );
};

export default UpdateLogs;
