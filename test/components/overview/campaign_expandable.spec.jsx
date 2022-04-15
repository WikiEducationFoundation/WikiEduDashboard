import React from 'react';
import { mount } from 'enzyme';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import reducer from '../../../app/assets/javascripts/reducers';
import '../../testHelper';
import CampaignEditable from '../../../app/assets/javascripts/components/overview/campaign_editable.jsx';

describe('CampaignEditable', () => {
  const campaigns = ['Cool campaign'];
  const course = {
    string_prefix: 'course_generic',
    id: 1,
  };
  const allCampaigns = [
    { title: 'Cool campaign', slug: 'cool_campaign' },
    { title: 'Not cool campaign', slug: 'not_cool_campaign' }
  ];
  const initialState = { campaigns: { campaigns } };
  const reduxStoreWithCampaigns = createStore(reducer, initialState, compose(applyMiddleware(thunk)));

  it('it opens the component when editable is true', () => {
    const TestButton = mount(
      <Provider store={reduxStoreWithCampaigns}>
        <CampaignEditable
          campaigns={campaigns}
          allCampaigns={allCampaigns}
          course={course}
          editable={true}
        />
      </Provider>
    );
    expect(TestButton.find('.pop__container.campaigns.open')).toExist;
  });

  it('it includes a plus button when is closed to open the expandable', () => {
    const TestButton = mount(
      <Provider store={reduxStoreWithCampaigns}>
        <CampaignEditable
          campaigns={campaigns}
          allCampaigns={allCampaigns}
          course={course}
          editable={false}
        />
      </Provider>
    );
    expect(TestButton.find('.button.border.plus.open')).toExist;
  });
});
