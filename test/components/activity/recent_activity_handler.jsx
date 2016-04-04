import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';

import '../../testHelper';

import RecentActivityHandler from '../../../app/assets/javascripts/components/activity/recent_activity_handler.jsx';

describe('RecentActivityHandler', () => {
  const TestRow = ReactTestUtils.renderIntoDocument(
    <div>
      <RecentActivityHandler>
        <h1>Child</h1>
      </RecentActivityHandler>
    </div>
  );

  it('renders children', () => {
    expect(TestRow.querySelector('h1')).to.exist();
  });

  it('renders links', () => {
    expect(TestRow.querySelectorAll('a').length).to.eq(3);
  });
});
