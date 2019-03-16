import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';
import { Provider } from 'react-redux';

import '../../testHelper';
import Notifications from '../../../app/assets/javascripts/components/common/notifications.jsx';


describe('Notifications', () => {
  it('renders', () => {
    const rendered = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStore}>
        <Notifications />
      </Provider>
    );
    expect(rendered).to.exist;
  });

  it('updates via API_FAIL action and removes via close', (done) => {
    const rendered = ReactTestUtils.renderIntoDocument(
      <div>
        <Provider store={reduxStore}>
          <Notifications />
        </Provider>
      </div>
    );

    let rows = rendered.querySelectorAll('.notice');
    expect(rows.length).to.eq(0);

    reduxStore.dispatch({
      type: 'API_FAIL',
      data: {
        responseJSON: {
          error: 'Test error'
        }
      }
    });

    rows = rendered.querySelectorAll('.notice');
    expect(rows.length).to.eq(1);

    const close = rendered.querySelector('svg');
    Simulate.click(close);

    return setImmediate(() => {
      rows = rendered.querySelectorAll('.notice');
      expect(rows.length).to.eq(0);
      return done();
    });
  });
});
