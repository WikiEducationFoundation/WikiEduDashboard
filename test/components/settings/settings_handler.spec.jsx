import configureMockStore from 'redux-mock-store';
import React from 'react';
import thunk from 'redux-thunk';
import { shallow } from 'enzyme';
import { Provider } from 'react-redux';

import '../../testHelper';
import SettingsHandler from '../../../app/assets/javascripts/components/settings/settings_handler.jsx';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('SettingsHandler', () => {
  it('passes adminUsers to AdminUsersList', () => {
    const expectedAdminUsers = [{ id: 1, username: 'testUser', real_name: 'real name', permissions: 3 }];
    const store = mockStore({
      settings: {
        adminUsers: expectedAdminUsers,
        revokingAdmin: {
          status: false,
          username: null,
        }
      },
      notifications: [],
    });
    const wrapper = shallow(
      <Provider store={store}>
        <SettingsHandler />
      </Provider>
    );

    const container = wrapper.dive({ context: { store } }).dive();

    expect(
      container.find('AdminUserList').first().props().adminUsers
    ).to.eql(expectedAdminUsers);
  });
});
