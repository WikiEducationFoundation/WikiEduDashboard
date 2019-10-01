import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import '../../testHelper';
import Milestones from '../../../app/assets/javascripts/components/overview/milestones.jsx';

describe('Milestones', () => {
  const block = { id: 1, kind: 2, content: 'Tacos are great' };
  const week = { order: 1, blocks: [block] };
  const week2 = { order: 2, blocks: [] };

  const TestMilestonesWithWeeks = ReactTestUtils.renderIntoDocument(
    <Milestones
      timelineStart={'2018-07-20T23:59:59.000Z'}
      weeks={[week, week2]}
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
    />
  );

  it('does not render block if empty', () => {
    expect(TestMilestonesWithoutWeeks.render()).toEqual(null);
  });
});
