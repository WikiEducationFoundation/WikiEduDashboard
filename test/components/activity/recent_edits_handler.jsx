import '../../testHelper';

import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import sinon from 'sinon';

import RecentEditsHandler from '../../../app/assets/javascripts/components/activity/recent_edits_handler.jsx';

describe('RecentEditsHandler', () => {
  it('can toggle course scope', () => {
    const spy = sinon.spy();

    RecentEditsHandler.__Rewire__('ServerActions', {
      fetchRecentEdits: spy
    });

    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <RecentEditsHandler />
      </div>
    );

    // called once when mounted
    expect(spy.callCount).to.eq(1);

    // Trigger checkbox change
    const cb = TestDom.querySelector('input[type=checkbox]');
    Simulate.change(cb, { target: { checked: true } });

    // Expect to have been called again with scoped set to true
    expect(spy.secondCall.calledWith({ scoped: true })).to.eq(true);

    RecentEditsHandler.__ResetDependency__('ServerActions');
  });
});
