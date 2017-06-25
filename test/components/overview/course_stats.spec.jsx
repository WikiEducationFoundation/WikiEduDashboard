import '../../testHelper';
import React from 'react';
import { shallow } from 'enzyme'; // Shallow rendering is useful to constrain yourself to testing
 // a component as a unit, and to ensure that your tests aren't indirectly asserting on behavior of child components.
import CourseStats from '../../../app/assets/javascripts/components/overview/course_stats.jsx';

describe('for view count zero', () => {
  const course = {
    view_count: 0
  };
  const stats = (
    <CourseStats
      course={course}
    />
  );
  const msgString = I18n.t('metrics.view_data_unavailable');
  it('renders view data unavailable message', () => {
    const wrapper = shallow(stats);
    // expect(wrapper.contains(<div className="stat-display__data"></div>)).to.be.true;
    expect(wrapper.contains(msgString)).to.be.true;
  });
});

describe('for view count greater than zero', () => {
  const course = {
    view_count: 3
  };
  const component = (
    <CourseStats
      course={course}
    />
  );
  it('doesn\'t render view data unavailable message', () => {
    const wrapper = shallow(component);
    expect(wrapper.contains(<div className="stat-display__data"></div>)).to.be.false;
  });
});
