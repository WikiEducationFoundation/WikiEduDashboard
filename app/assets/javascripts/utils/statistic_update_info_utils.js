import { addSeconds, formatDistanceToNow, isAfter } from 'date-fns';
import { toDate } from './date_utils';

const firstUpdateTime = (first_update) => {
  const latency = Math.round(first_update.queue_latency);
  const enqueuedAt = toDate(first_update.enqueued_at);
  return addSeconds(enqueuedAt, latency);
};

const lastSuccessfulUpdateMoment = (update_logs) => {
  const updateTimesLogs = Object.values(update_logs).filter(log => log.end_time !== undefined);
  if (updateTimesLogs.length === 0) return null;
  const lastSuccessfulUpdateTime = updateTimesLogs[updateTimesLogs.length - 1].end_time;
  return new Date(lastSuccessfulUpdateTime);
};

const getLastUpdateMessage = (course) => {
  let lastUpdateMessage = '';
  let nextUpdateMessage = '';
  let isNextUpdateAfter = false;
  const lastUpdateMoment = lastSuccessfulUpdateMoment(course.flags.update_logs);
  if (lastUpdateMoment) {
    const averageDelay = course.updates.average_delay ?? 0;
    lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${formatDistanceToNow(lastUpdateMoment, { addSuffix: true })}.`;
    const nextUpdateExpectedTime = addSeconds(lastUpdateMoment, averageDelay);
    isNextUpdateAfter = isAfter(nextUpdateExpectedTime, new Date());
    nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${formatDistanceToNow(nextUpdateExpectedTime, { addSuffix: true })}.`;
  }
  return [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
};

const nextUpdateExpected = (course) => {
  if (!course.flags.update_logs) {
   return formatDistanceToNow(firstUpdateTime(course.flags.first_update), { addSuffix: true });
  }
  if (lastSuccessfulUpdateMoment(course.flags.update_logs) === null) {
    return 'unknown';
  }
  const lastUpdateMoment = lastSuccessfulUpdateMoment(course.flags.update_logs);
  const averageDelay = course.updates.average_delay || 0;
  const nextUpdateTime = addSeconds(lastUpdateMoment, averageDelay);
  return formatDistanceToNow(nextUpdateTime, { addSuffix: true });
};


const getUpdateMessage = (course) => {
  if (!course.flags.update_logs) {
    return getFirstUpdateMessage(course);
  }
  const successfulUpdate = lastSuccessfulUpdateMoment(course.flags.update_logs);
  if (course.flags.update_logs && successfulUpdate !== null) {
    const ans = getLastUpdateMessage(course);
    return ans;
  }
  return [`${I18n.t('metrics.no_update')}`, '', ''];
};

const getFirstUpdateMessage = (course) => {
  let lastUpdateMessage = '';
  let nextUpdateMessage = '';
  let isNextUpdateAfter = false;
  if (course.flags.first_update) {
    const nextUpdateExpectedTime = firstUpdateTime(course.flags.first_update);
    isNextUpdateAfter = isAfter(nextUpdateExpectedTime, new Date());
    nextUpdateMessage = `${I18n.t('metrics.first_update')}: ${formatDistanceToNow(nextUpdateExpectedTime, { addSuffix: true })}.`;
    lastUpdateMessage = `${I18n.t('metrics.enqueued_update')}`;
  } else {
    lastUpdateMessage = `${I18n.t('metrics.no_update')}`;
  }
  return [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
};

const getLastUpdateSummary = (course) => {
  if (course.updates.last_update === null || lastSuccessfulUpdateMoment(course.flags.update_logs) === null) {
    return I18n.t('metrics.no_update');
  }
  const errorCount = course.updates.last_update.error_count;
  if (errorCount === 0) {
    return `${I18n.t('metrics.last_update_success')}`;
  } else if (errorCount > 0) {
    return `${I18n.t('metrics.error_count_message', { error_count: errorCount })}`;
  } else if (course.updates.last_update.orphan_lock_failure) {
    return `${I18n.t('metrics.last_update_failed')}`;
  }
};

const getTotaUpdatesMessage = (course) => {
  if (!course.flags.update_logs) {
    return `${I18n.t('metrics.total_updates')}: 0.`;
  }
  const updateNumbers = Object.keys(course.flags.update_logs);
  return `${I18n.t('metrics.total_updates')}: ${updateNumbers[updateNumbers.length - 1]}.`;
};

const getUpdateLogs = (course) => {
  if (course.flags.update_logs) {
    return Object.values(course.flags.update_logs);
  }
  return [];
};
export { getUpdateMessage, getLastUpdateMessage, getFirstUpdateMessage, firstUpdateTime, lastSuccessfulUpdateMoment, nextUpdateExpected, getLastUpdateSummary, getTotaUpdatesMessage, getUpdateLogs };
