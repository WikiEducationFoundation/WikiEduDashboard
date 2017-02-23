import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import '../../testHelper';
import AvailableActions from '../../../app/assets/javascripts/components/overview/available_actions.jsx';

describe('AvailableActions', () => {
  it('Displays no actions for ended course', () => {
    const TestAvailableActions = ReactTestUtils.renderIntoDocument(
      <AvailableActions
        current_user={{}}
      />
    );
    TestAvailableActions.setState({
      course: {
        ended: true
      }
    });
    const p = ReactTestUtils.findRenderedDOMComponentWithTag(TestAvailableActions, 'p');
    expect(p.textContent).to.eq('No available actions');
  });
});
