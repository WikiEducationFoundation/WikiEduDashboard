import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import configureMockStore from 'redux-mock-store';
import '../../testHelper';
import AvailableActions from '../../../app/assets/javascripts/components/overview/available_actions.jsx';

const mockStore = configureMockStore()({});

describe('AvailableActions', () => {
  it('displays no actions for ended course', () => {
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

    const text = TestAvailableActions.find('.available-action').text();
    expect(text).toEqual('No available actions');
  });

  it('displays administrative P&E actions if the user is an admin', () => {
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

    const actions = TestAvailableActions.find('.available-action');
    expect(actions.length).toEqual(5);

    const deleteButton = actions.at(0);
    expect(deleteButton.text()).toEqual('Delete course');

    const enableAccountRequestsButton = actions.at(1);
    expect(enableAccountRequestsButton.text()).toEqual('Enable account requests');

    const downloadStatsButton = actions.at(2);
    expect(downloadStatsButton.text()).toEqual('Download stats');

    const embedStatsButton = actions.at(3);
    expect(embedStatsButton.text()).toEqual('Embed Course Stats');

    const cloneCourseButton = actions.at(4);
    expect(cloneCourseButton.text()).toEqual('Clone This Course');
  });

  it('displays administrative WikiEd actions if the user is an admin', () => {
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

    const actions = TestAvailableActions.find('.available-action');
    expect(actions.length).toEqual(4);

    const enableAccountRequestsButton = actions.at(0);
    expect(enableAccountRequestsButton.text()).toEqual('Enable account requests');

    const downloadStatsButton = actions.at(1);
    expect(downloadStatsButton.text()).toEqual('Download stats');

    const embedStatsButton = actions.at(2);
    expect(embedStatsButton.text()).toEqual('Embed Course Stats');

    const cloneCourseButton = actions.at(3);
    expect(cloneCourseButton.text()).toEqual('Clone This Course');
  });
});
