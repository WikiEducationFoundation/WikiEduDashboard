import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import StatisticsUpdateInfo from '../../../app/assets/javascripts/components/overview/statistics_update_info.jsx';

describe('for a mixture of successful and failure update logs', () => {
  const current = moment();
  const oneHourAgo = moment().subtract(1, 'hours');
  const twoHoursAgo = moment().subtract(2, 'hours');
  const fourHoursAgo = moment().subtract(4, 'hours');
  const fiveHoursAgo = moment().subtract(5, 'hours');
  const sixHoursAgo = moment().subtract(6, 'hours');

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
    const lastSuccessfulUpdateMoment = moment().subtract(1, 'hours');
    const lastSuccessfulUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastSuccessfulUpdateMoment.fromNow()}`;
    const nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${lastSuccessfulUpdateMoment.add(course.updates.average_delay, 'seconds').fromNow()}`;

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

    const lastSuccessfulUpdateMoment = moment();
    const lastSuccessfulUpdateMessage = `${I18n.t('metrics.last_update')}: ${lastSuccessfulUpdateMoment.fromNow()}`;
    const nextUpdateMessage = `${I18n.t('metrics.next_update')}: ${lastSuccessfulUpdateMoment.add(course.updates.average_delay, 'seconds').fromNow()}`;

    const wrapper = shallow(<StatisticsUpdateInfo course={course}/>);
    expect(wrapper.text().includes(lastSuccessfulUpdateMessage)).toEqual(true);
    expect(wrapper.text().includes(nextUpdateMessage)).toEqual(true);
  });
});
