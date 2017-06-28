import '../../testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import CourseStats from '../../../app/assets/javascripts/components/overview/course_stats.jsx';

describe('for view count zero and edited count greater than 0', () => {
  const course = {
    view_count: '0',
    edited_count: '1',
    upload_usages_count: 0
  };
  const testStats = (
    <CourseStats
      course={course}
    />
  );
  const msgString = I18n.t('metrics.view_data_unavailable');
  it('renders view data unavailable message', () => {
    const wrapper = shallow(testStats);
    expect(wrapper.contains(msgString)).to.be.true;
  });
});

describe('for view count greater than zero', () => {
  const course = {
    view_count: '3',
    upload_usages_count: 0
  };
  const testStats = (
    <CourseStats
      course={course}
    />
  );
  const msgString = I18n.t('metrics.view_data_unavailable');
  it('doesn\'t render view data unavailable message', () => {
    const wrapper = shallow(testStats);
    expect(wrapper.contains(msgString)).to.be.false;
  });
});
