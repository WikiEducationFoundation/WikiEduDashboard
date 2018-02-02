import React from 'react';
import moment from 'moment';

const StatisticsUpdateInfo = ({ course }) => {
  if (course.ended || Features.wikiEd || !course.updates) {
    return <div />;
  }
  const lastUpdate = course.updates.last_update;
  const averageDelay = course.updates.average_delay;
  let lastUpdateMessage;
  if (lastUpdate) {
    lastUpdateMessage = `${I18n.t('metrics.last_update')}: ${moment(lastUpdate).fromNow()}`;
  }
  const nextUpdateExpectedTime = moment(lastUpdate).add(averageDelay, "seconds");
  let nextUpdateMessage;
  if (nextUpdateExpectedTime.isAfter()) {
    nextUpdateMessage = `. ${I18n.t('metrics.next_update')}: ${nextUpdateExpectedTime.fromNow()}`;
  }
  return (
    <div className="pull-right">
      <small className="mb2">{lastUpdateMessage}{nextUpdateMessage}</small>
    </div>
  );
};

export default StatisticsUpdateInfo;
