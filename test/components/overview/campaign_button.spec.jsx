import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import CampaignButton from '../../../app/assets/javascripts/components/overview/campaign_button.jsx';

describe('CampaignButton', () => {
  // const CampaignButton = rewire('../../../app/assets/javascripts/components/overview/campaign_button.jsx');
  // const CampaignStore = rewire('../../../app/assets/javascripts/stores/campaign_store.coffee');

  it('renders a plus button', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <CampaignButton
        campaigns={[]}
        show={true}
      />
    );
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus');
  });
});
