import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import rewire from 'rewire';

let Milestones = rewire('../../../app/assets/javascripts/components/overview/milestones.jsx').default;

describe('Milestones', () => {
  let course = { string_prefix: 'courses' };
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
    return expect(milestones.innerHTML).to.include('<p>Tacos are great</p>');
  }
  );

  return it('does not render block if empty', () => {
    TestMilestones.setState({ weeks: [week2] });
    return expect(TestMilestones.render()).to.equal(null);
  }
  );
}
);
