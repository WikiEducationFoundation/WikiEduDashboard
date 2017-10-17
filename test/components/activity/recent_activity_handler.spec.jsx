import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import RecentActivityHandler from '../../../app/assets/javascripts/components/activity/recent_activity_handler.jsx';

describe('RecentActivityHandler', () => {
  const TestDom = ReactTestUtils.renderIntoDocument(
    <div>
      <RecentActivityHandler>
        <h1>Child</h1>
      </RecentActivityHandler>
    </div>
  );

  it('renders children', () => {
    expect(TestDom.querySelector('h1')).to.exist;
  });

  it('renders links', () => {
    expect(TestDom.querySelectorAll('a').length).to.eq(4);
  });
});
