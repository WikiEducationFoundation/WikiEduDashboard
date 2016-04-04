import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import sinon from 'sinon';

import '../../testHelper';

import PlagiarismHandler from '../../../app/assets/javascripts/components/activity/plagiarism_handler.jsx';

describe('PlagiarismHandler', () => {
  it('can toggle course scope', () => {
    const spy = sinon.spy();

    PlagiarismHandler.__Rewire__('ServerActions', {
      fetchSuspectedPlagiarism: spy
    });

    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <PlagiarismHandler />
      </div>
    );

    // called once when mounted
    expect(spy.callCount).to.eq(1);

    // Trigger checkbox change
    const cb = TestDom.querySelector('input[type=checkbox]');
    Simulate.change(cb, { target: { checked: true } });

    // Expect to have been called again with scoped set to true
    expect(spy.secondCall.calledWith({ scoped: true })).to.eq(true);
  });
});
