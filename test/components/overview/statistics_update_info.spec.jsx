import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import StatisticsUpdateInfo from '../../../app/assets/javascripts/components/overview/statistics_update_info.jsx';
import { addSeconds, formatDistanceToNow, subHours } from 'date-fns';

describe('for a mixture of successful and failure update logs', () => {
  const current = new Date();
  const oneHourAgo = subHours(current, 1);
  const twoHoursAgo = subHours(current, 2);
  const fourHoursAgo = subHours(current, 4);
  const fiveHoursAgo = subHours(current, 5);
  const sixHoursAgo = subHours(current, 6);

  const firstSuccessLog = {
    start_time: fiveHoursAgo.toISOString(),
    end_time: fourHoursAgo.toISOString(),
    error_count: 2,
    sentry_tag_uuid: '12ab-34cd'
  };

  const secondSuccessLog = {
    start_time: twoHoursAgo.toISOString(),
    end_time: oneHourAgo.toISOString(),
    error_count: 0,
    sentry_tag_uuid: '56ef-78gh'
  };

  const thirdSuccessLog = {
    start_time: oneHourAgo.toISOString(),
    end_time: current.toISOString(),
    error_count: 0,
    sentry_tag_uuid: '78ij-90kl'
  };

  it('renders course update times information correctly if last update is a failure', () => {
    const firstFailureLog = { orphan_lock_failure: sixHoursAgo.toISOString() };
    const lastFailureLog = { orphan_lock_failure: current.toISOString() };

    const course = {
      flags: {
        update_logs: {
          1: firstFailureLog,
          2: firstSuccessLog,
          3: secondSuccessLog,
          4: lastFailureLog
        }
      },
      updates: {
        last_update: lastFailureLog,
        average_delay: 3600
      }
    };
    const lastSuccessfulUpdateMoment = subHours(new Date(), 1);
    const lastSuccessfulUpdateMessage = `${I18n.t('metrics.last_update')}: ${formatDistanceToNow(lastSuccessfulUpdateMoment, { addSuffix: true })}`;
    const nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${formatDistanceToNow(addSeconds(lastSuccessfulUpdateMoment, course.updates.average_delay), { addSuffix: true })}`;

    const wrapper = shallow(<StatisticsUpdateInfo course={course}/>);
    expect(wrapper.text().includes(lastSuccessfulUpdateMessage)).toEqual(true);
    expect(wrapper.text().includes(nextUpdateMessage)).toEqual(false);
  });

  it('renders course update times information correctly if last update is a success', () => {
    const failureLog = { orphan_lock_failure: twoHoursAgo.toISOString() };

    const course = {
      flags: {
        update_logs: {
          1: firstSuccessLog,
          2: failureLog,
          3: thirdSuccessLog
        }
      },
      updates: {
        last_update: thirdSuccessLog,
        average_delay: 3600
      }
    };

    const lastSuccessfulUpdateMoment = new Date();
    const lastSuccessfulUpdateMessage = `${I18n.t('metrics.last_update')}: ${formatDistanceToNow(lastSuccessfulUpdateMoment, { addSuffix: true })}`;
    const nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${formatDistanceToNow(addSeconds(lastSuccessfulUpdateMoment, course.updates.average_delay), { addSuffix: true })}`;

    const wrapper = shallow(<StatisticsUpdateInfo course={course}/>);
    expect(wrapper.text().includes(lastSuccessfulUpdateMessage)).toEqual(true);
    expect(wrapper.text().includes(nextUpdateMessage)).toEqual(true);
  });
});
