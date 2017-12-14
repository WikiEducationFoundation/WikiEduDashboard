import '../../testHelper';
import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';
import McFly from 'mcfly';

const Flux = new McFly();
const { dispatcher } = Flux;

import NotificationStore from '../../../app/assets/javascripts/stores/notification_store.js';
import Notifications from '../../../app/assets/javascripts/components/common/notifications.jsx';

describe('Notifications', () => {
  it('renders', () => {
    const rendered = ReactTestUtils.renderIntoDocument(
      <Notifications store={reduxStore} />
    );
    expect(rendered).to.exist;
  });

  it('updates via API_FAIL action and removes via close', (done) => {
    NotificationStore.clearNotifications();

    const rendered = ReactTestUtils.renderIntoDocument(
      <div>
        <Notifications store={reduxStore} />
      </div>
    );

    let rows = rendered.querySelectorAll('.notice');
    expect(rows.length).to.eq(0);

    dispatcher.dispatch({
      actionType: 'API_FAIL',
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
