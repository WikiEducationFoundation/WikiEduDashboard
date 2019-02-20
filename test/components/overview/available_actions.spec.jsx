import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import configureMockStore from 'redux-mock-store';
import '../../testHelper';
import AvailableActions from '../../../app/assets/javascripts/components/overview/available_actions.jsx';

const mockStore = configureMockStore()({});

describe('AvailableActions', () => {
  it('Displays no actions for ended course', () => {
    const endedCourse = {
      ended: true
    };

    const TestAvailableActions = mount(
      <Provider store={mockStore}>
        <AvailableActions
          course={endedCourse}
          current_user={{}}
          updateCourse={sinon.spy()}
        />
      </Provider>
    );

    const text = TestAvailableActions.find('p').text();
    expect(text).to.eq('No available actions');
  });

  it('Displays administrative P&E actions if the user is an admin', () => {
    const course = {
      id: 999,
      ended: false,
      published: true,
      submitted: true
    };
    const user = {
      admin: true
    };

    const TestAvailableActions = mount(
      <Provider store={mockStore}>
        <AvailableActions
          course={course}
          current_user={user}
          updateCourse={sinon.spy()}
        />
      </Provider>
    );

    const actions = TestAvailableActions.find('p');
    expect(actions.length).to.eq(4);

    const deleteButton = actions.at(0);
    expect(deleteButton.text()).to.eq('Delete course');

    const enableAccountRequestsButton = actions.at(1);
    expect(enableAccountRequestsButton.text()).to.eq('Enable account requests');

    const downloadStatsButton = actions.at(2);
    expect(downloadStatsButton.text()).to.eq('Download stats');

    const embedStatsButton = actions.at(3);
    expect(embedStatsButton.text()).to.eq('Embed Course Stats');
  });

  it('Displays administrative WikiEd actions if the user is an admin', () => {
    global.Features.wikiEd = true;
    const course = {
      id: 999,
      ended: false,
      published: true,
      submitted: true
    };
    const user = {
      admin: true
    };

    const TestAvailableActions = mount(
      <Provider store={mockStore}>
        <AvailableActions
          course={course}
          current_user={user}
          updateCourse={sinon.spy()}
        />
      </Provider>
    );

    const actions = TestAvailableActions.find('p');
    expect(actions.length).to.eq(5);

    const deleteButton = actions.at(0);
    expect(deleteButton.text()).to.eq('Greet students');

    const enableAccountRequestsButton = actions.at(1);
    expect(enableAccountRequestsButton.text()).to.eq('Enable account requests');

    const downloadStatsButton = actions.at(2);
    expect(downloadStatsButton.text()).to.eq('Download stats');

    const embedStatsButton = actions.at(3);
    expect(embedStatsButton.text()).to.eq('Embed Course Stats');

    const cloneCourseButton = actions.at(4);
    expect(cloneCourseButton.text()).to.eq('Clone This Course');
  });
});
