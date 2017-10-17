import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import sinon from 'sinon';

import RecentUploadsHandler from '../../../app/assets/javascripts/components/activity/recent_uploads_handler.jsx';

describe('RecentUploadsHandler', () => {
  it('fetches recent uploads', () => {
    const spy = sinon.spy();

    RecentUploadsHandler.__Rewire__('ServerActions', {
      fetchRecentUploads: spy
    });

    ReactTestUtils.renderIntoDocument(
      <div>
        <RecentUploadsHandler />
      </div>
    );

    // called once when mounted
    expect(spy.callCount).to.eq(1);
  });
});
