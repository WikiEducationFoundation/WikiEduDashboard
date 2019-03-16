import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';

import reducer from '../../../app/assets/javascripts/reducers';
import '../../testHelper';
import CampaignList from '../../../app/assets/javascripts/components/overview/campaign_list.jsx';

describe('CampaignList', () => {
  const campaigns = [{ title: 'Cool campaign', slug: 'cool_campaign' }];
  const course = {
    string_prefix: 'course_generic',
    id: 1,
  };
  const initialState = { campaigns: { campaigns } };
  const reduxStoreWithCampaigns = createStore(reducer, initialState, compose(applyMiddleware(thunk)));

  it('it keeps the component closed when editable is false', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStoreWithCampaigns}>
        <CampaignList
          campaigns={campaigns}
          course={course}
          editable={false}
        />
      </Provider>
    );
    ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'campaigns');
  });
});
