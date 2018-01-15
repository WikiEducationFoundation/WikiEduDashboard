import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import '../../testHelper';
import CampaignButton from '../../../app/assets/javascripts/components/overview/campaign_button.jsx';

describe('CampaignButton', () => {
  it('renders a plus button', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <CampaignButton
        store={reduxStore}
        campaigns={[]}
        show={true}
      />
    );
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus');
  });
});
