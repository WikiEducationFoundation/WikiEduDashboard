import moment from 'moment';

const firstUpdateTime = (first_update) => {
  const latency = Math.round(first_update.queue_latency);
  const enqueuedAt = moment(first_update.enqueued_at);
  return moment(enqueuedAt).add(latency, 'seconds');
};

const lastSuccessfulUpdateMoment = (update_logs) => {
  const updateTimesLogs = Object.values(update_logs).filter(log => log.end_time !== undefined);
  if (updateTimesLogs.length === 0) return null;
  const lastSuccessfulUpdateTime = updateTimesLogs[updateTimesLogs.length - 1].end_time;
  return moment.utc(lastSuccessfulUpdateTime);
};

const getLastUpdateMessage = (course) => {
  let lastUpdateMessage = '';
  let nextUpdateMessage = '';
  let isNextUpdateAfter = false;
  const lastUpdateMoment = lastSuccessfulUpdateMoment(course.flags.update_logs);
  if (lastUpdateMoment) {
    const averageDelay = course.updates.average_delay;
    lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastUpdateMoment.fromNow()}.`;
    const nextUpdateExpectedTime = lastUpdateMoment.add(averageDelay, 'seconds');
    isNextUpdateAfter = nextUpdateExpectedTime.isAfter();
    nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${nextUpdateExpectedTime.fromNow()}.`;
  }
  return [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
};

const nextUpdateExpected = (course) => {
  const lastUpdateMoment = lastSuccessfulUpdateMoment(course.flags.update_logs);
  const averageDelay = course.updates.average_delay;
  const nextUpdateTime = lastUpdateMoment.add(averageDelay, 'seconds');
  return nextUpdateTime.fromNow();
};

const getFirstUpdateMessage = (course) => {
  let lastUpdateMessage = '';
  let nextUpdateMessage = '';
  let isNextUpdateAfter = false;
  if (course.flags.first_update) {
    const nextUpdateExpectedTime = firstUpdateTime(course.flags.first_update);
    isNextUpdateAfter = nextUpdateExpectedTime.isAfter();
    nextUpdateMessage = `${I18n.t('metrics.first_update')}: ${nextUpdateExpectedTime.fromNow()}.`;
    lastUpdateMessage = `${I18n.t('metrics.enqueued_update')}`;
  } else {
    lastUpdateMessage = `${I18n.t('metrics.no_update')}`;
  }
  return [lastUpdateMessage, nextUpdateMessage, isNextUpdateAfter];
};

export { getLastUpdateMessage, getFirstUpdateMessage, firstUpdateTime, lastSuccessfulUpdateMoment, nextUpdateExpected };
