import { addSeconds, formatDistanceToNow, isAfter, format } from 'date-fns';
import { toDate } from './date_utils';
import { useSelector } from 'react-redux';

const firstUpdateTime = (first_update) => {
  if (!first_update) return null;
  const latency = Math.round(first_update.queue_latency);
  const enqueuedAt = toDate(first_update.enqueued_at);
  return addSeconds(enqueuedAt, latency);
};

const lastSuccessfulUpdateMoment = (update_logs) => {
  if (!update_logs) return null;
  const updateTimesLogs = Object.values(update_logs).filter(log => log.end_time !== undefined);
  if (updateTimesLogs.length === 0) return null;
  const lastSuccessfulUpdateTime = updateTimesLogs[updateTimesLogs.length - 1].end_time;
  return new Date(lastSuccessfulUpdateTime);
};

const isNextUpdateAfterUpdatesEnd = (course, nextUpdateExpectedTime, updatesEndMoment) => {
  if (!course?.flags?.update_logs) return [];
  return isAfter(nextUpdateExpectedTime, new Date()) && isAfter(updatesEndMoment, new Date());
};

const getLastUpdateMessage = (course) => {
  let lastUpdateMessage = '';
  let nextUpdateMessage = '';
  let isNextUpdateAfter = false;
  const lastUpdateMoment = lastSuccessfulUpdateMoment(course.flags.update_logs);
  const updatesEndMoment = toDate(course.update_until);
  if (lastUpdateMoment) {
    const averageDelay = course.updates.average_delay ?? 0;
    lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${formatDistanceToNow(lastUpdateMoment, { addSuffix: true })}.`;
    const nextUpdateExpectedTime = addSeconds(lastUpdateMoment, averageDelay);
    isNextUpdateAfter = isNextUpdateAfterUpdatesEnd(nextUpdateExpectedTime, updatesEndMoment);
    nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${formatDistanceToNow(nextUpdateExpectedTime, { addSuffix: true })}.`;
  }
  return [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
};

const nextUpdateExpected = (course) => {
  if (!course?.flags?.update_logs) {
    const firstUpdate = course?.flags?.first_update;
    if (!firstUpdate) {
      return I18n.t('metrics.no_update_yet', { defaultValue: 'No updates available yet.' });
    }
    try {
      return formatDistanceToNow(firstUpdateTime(firstUpdate), { addSuffix: true });
    } catch {
      return I18n.t('metrics.no_update_yet', { defaultValue: 'No updates available yet.' });
    }
  }

  const lastUpdateMoment = lastSuccessfulUpdateMoment(course.flags.update_logs);
  if (!lastUpdateMoment) {
    return I18n.t('metrics.no_update_yet', { defaultValue: 'No updates available yet.' });
  }

  const averageDelay = course?.updates?.average_delay || 0;
  const nextUpdateTime = addSeconds(lastUpdateMoment, averageDelay);

  if (isNaN(nextUpdateTime)) {
    return I18n.t('metrics.no_update_yet', { defaultValue: 'No updates available yet.' });
  }

  return formatDistanceToNow(nextUpdateTime, { addSuffix: true });
};


const getUpdateMessage = (course) => {
  if (!course?.flags) return [`${I18n.t('metrics.no_update')}`, '', ''];
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
  const updatesEndMoment = toDate(course.update_until);
  if (course.flags.first_update) {
    const nextUpdateExpectedTime = firstUpdateTime(course.flags.first_update);
    isNextUpdateAfter = isNextUpdateAfterUpdatesEnd(nextUpdateExpectedTime, updatesEndMoment);
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

// Tracking Description
const computeTrackingDescription = (course) => {
  if (!course) return null;

  const start = new Date(course.start);
  const end = new Date(course.end);
  const now = new Date();

  const wikiList = (() => {
    const wikis = course.all_wikis || course.wikis || [];
    if (!Array.isArray(wikis) || wikis.length === 0) return 'no wikis configured';
    const languages = wikis.map(w => w.language).filter(Boolean);
    return languages.length > 0 ? languages.join(', ') : 'no wikis configured';
  })();

  if (start > now) {
    const startDate = format(start, 'MMMM d, yyyy');
    return `This program is scheduled to begin on ${startDate}. `
      + `When it starts, edits from ${wikiList} will be tracked automatically.`;
  }

  const noStudents = course.student_count === 0;
  const campaigns = useSelector(state => state.campaigns);
  const noCampaigns = campaigns.length === 0;

  if (noStudents || noCampaigns) {
    return 'This program currently has no students or campaigns, so no edits can be tracked. '
     + 'Please add students and campaigns to enable tracking.';
  }

  const endDate = format(end, 'MMMM d, yyyy');
  const updateUntil = new Date(end.getTime() + 7 * 24 * 60 * 60 * 1000);
  const updateUntilFormatted = format(updateUntil, 'MMMM d, yyyy');

  return `Edits for this program from ${wikiList} will be tracked through ${endDate}. `
   + `The dashboard will continue updating statistics until ${updateUntilFormatted}.`;
};

export { getUpdateMessage, getLastUpdateMessage, getFirstUpdateMessage, firstUpdateTime, lastSuccessfulUpdateMoment, nextUpdateExpected, getLastUpdateSummary, getTotaUpdatesMessage, getUpdateLogs, computeTrackingDescription };
