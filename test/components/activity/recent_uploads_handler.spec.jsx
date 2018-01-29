import React from 'react';
import { mount } from 'enzyme';
import sinon from 'sinon';

import '../../testHelper';

import { RecentUploadsHandlerBase } from '../../../app/assets/javascripts/components/activity/recent_uploads_handler.jsx';

describe('RecentUploadsHandler', () => {
  it('fetches recent uploads', () => {
    const spy = sinon.spy();

    mount(<RecentUploadsHandlerBase fetchRecentUploads={spy} uploads={[]} />);

    // called once when mounted
    expect(spy.callCount).to.eq(1);
  });
});
