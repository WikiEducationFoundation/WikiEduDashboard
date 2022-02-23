import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import '../../testHelper';
import Milestones from '../../../app/assets/javascripts/components/overview/milestones.jsx';

describe('Milestones', () => {
  const block = { id: 1, kind: 2, content: 'Tacos are great' };
  const weeks_1 = { order: 1, blocks: [block] };
  const weeks_2 = { order: 2, blocks: [] };
  const allWeeks_1 = { empty: false, weekNumber: 1, order: 1, blocks: [block] };
  const allWeeks_2 = { empty: true, weekNumber: 2 };
  const allWeeks_3 = { empty: false, weekNumber: 3, order: 2, blocks: [] }; 
  const course = { start: '2016-01-01', timeline_start: '2016-01-01' };

  const TestMilestonesWithWeeks = ReactTestUtils.renderIntoDocument(
    <Milestones
      timelineStart={'2018-07-20T23:59:59.000Z'}
      weeks={[weeks_1, weeks_2]}
      allWeeks = {[allWeeks_1, allWeeks_2, allWeeks_3]}
      course={course}
    />
  );

  it('renders block content in a <p> tag', () => {
    const milestones = ReactTestUtils.findRenderedDOMComponentWithClass(TestMilestonesWithWeeks, 'milestones');
    expect(milestones.innerHTML).toContain('<p>Tacos are great</p>');
  });

  const TestMilestonesWithoutWeeks = ReactTestUtils.renderIntoDocument(
    <Milestones
      timelineStart={'2018-07-20T23:59:59.000Z'}
      weeks={[]}
      allWeeks={[]}
      course={course}
    />
  );

  it('does not render block if empty', () => {
    expect(TestMilestonesWithoutWeeks.render()).toEqual(null);
  });
});
