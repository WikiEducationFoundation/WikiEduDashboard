import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import Milestones from '../../../app/assets/javascripts/components/overview/milestones.jsx';

describe('Milestones', () => {
  const course = { string_prefix: 'courses' };
  const block = { id: 1, kind: 2, content: 'Tacos are great' };
  const week = { order: 1, blocks: [block] };
  const week2 = { order: 2, blocks: [] };

  const TestMilestones = ReactTestUtils.renderIntoDocument(
    <Milestones
      course={course}
    />
  );

  it('renders block content in a <p> tag', () => {
    TestMilestones.setState({ weeks: [week] });
    const milestones = ReactTestUtils.findRenderedDOMComponentWithClass(TestMilestones, 'milestones');
    expect(milestones.innerHTML).to.include('<p>Tacos are great</p>');
  }
  );

  it('does not render block if empty', () => {
    TestMilestones.setState({ weeks: [week2] });
    expect(TestMilestones.render()).to.equal(null);
  }
  );
}
);
