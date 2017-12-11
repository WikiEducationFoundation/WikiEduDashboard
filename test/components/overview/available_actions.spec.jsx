import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import '../../testHelper';
import AvailableActions from '../../../app/assets/javascripts/components/overview/available_actions.jsx';

describe('AvailableActions', () => {
  it('Displays no actions for ended course', () => {
    const TestAvailableActions = ReactTestUtils.renderIntoDocument(
      <AvailableActions
        store={reduxStore}
        current_user={{}}
      />
    );
    TestAvailableActions.setState({
      course: {
        ended: true
      }
    });
    // const p = ReactTestUtils.findRenderedDOMComponentWithTag(TestAvailableActions, 'p');
    // FIXME: make this work.
    // expect(p.textContent).to.eq('No available actions');
  });
});
