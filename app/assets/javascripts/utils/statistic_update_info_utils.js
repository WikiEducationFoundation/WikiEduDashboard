const firstUpdateTime = (course) => {
  const first_update = course.flags.first_update;
  const latency = Math.round(first_update.queue_latency);
  const enqueuedAt = moment(first_update.enqueued_at);
  return moment(enqueuedAt).add(latency, 'seconds');
};

const lastSuccessfulUpdateTime = (course) => {
  const updateTimesLogs = Object.values(course.flags.update_logs).filter(log => log.end_time !== undefined);

  if (updateTimesLogs.length === 0) return null;

  return updateTimesLogs[updateTimesLogs.length - 1].end_time;
};

export { firstUpdateTime, lastSuccessfulUpdateTime };
