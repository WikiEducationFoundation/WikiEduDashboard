import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import '../../testHelper';
import EnrollCard from '../../../app/assets/javascripts/components/enroll/enroll_card.jsx';

describe('EnrollCard', () => {
  it('Warns about ended course', () => {
    const TestEnrollCard = ReactTestUtils.renderIntoDocument(
      <EnrollCard
        course={{ ended: true }}
      />
    );
    const h1 = ReactTestUtils.findRenderedDOMComponentWithTag(TestEnrollCard, 'h1');
    expect(h1.textContent).to.eq('The course has ended.');
  });
});
