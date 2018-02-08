import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';

import reducer from '../../../app/assets/javascripts/reducers';
import '../../testHelper';
import CampaignButton from '../../../app/assets/javascripts/components/overview/campaign_button.jsx';

describe('CampaignButton', () => {
  const campaigns = ['Cool campaign'];
  const course = {
    string_prefix: 'course_generic',
    id: 1,
  };
  const allCampaigns = ['Cool campaign', 'Not cool campaign'];
  const initialState = { campaigns: { campaigns } };
  const reduxStoreWithCampaigns = createStore(reducer, initialState, compose(applyMiddleware(thunk)));

  it('it opens the component when editable is true and includes a plus button', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <CampaignButton
        store={reduxStoreWithCampaigns}
        campaigns={campaigns}
        allCampaigns={allCampaigns}
        course={course}
        editable={true}
      />
    );
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'campaigns container open');
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus');
  });

  it('it keeps the component closed when editable is false', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <CampaignButton
        store={reduxStoreWithCampaigns}
        campaigns={campaigns}
        allCampaigns={allCampaigns}
        course={course}
        editable={false}
      />
    );
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'campaigns container close');
  });
});
