import '../../testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import SettingsHandler from '../../../app/assets/javascripts/components/settings/settings_handler.jsx';

import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
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
    const wrapper = shallow(<Provider store={store} >
      <SettingsHandler />
    </Provider>);

    const container = wrapper.dive({ context: { store } }).dive();

    expect(
      container.find('AdminUserList').first().props().adminUsers
    ).to.eql(expectedAdminUsers);
  });
});
