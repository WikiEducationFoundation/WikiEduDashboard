import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import sinon from 'sinon';

import '../../testHelper';

import DidYouKnowHandler from '../../../app/assets/javascripts/components/activity/did_you_know_handler.jsx';

describe('DidYouKnowHandler', () => {
  it('can toggle course scope', () => {
    const spy = sinon.spy();

    DidYouKnowHandler.__Rewire__('ServerActions', {
      fetchDYKArticles: spy
    });

    const TestDom = ReactTestUtils.renderIntoDocument(
      <div>
        <DidYouKnowHandler />
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
