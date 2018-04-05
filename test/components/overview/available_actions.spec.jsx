import React from 'react';
import { mount } from 'enzyme';
import '../../testHelper';
import AvailableActions from '../../../app/assets/javascripts/components/overview/available_actions.jsx';

describe('AvailableActions', () => {
  it('Displays no actions for ended course', () => {
    const endedCourse = {
      ended: true
    };

    const TestAvailableActions = mount(
      <AvailableActions
        store={reduxStore}
        course={endedCourse}
        current_user={{}}
      />
    );

    const text = TestAvailableActions.find('p').text();
    expect(text).to.eq('No available actions');
  });
});
