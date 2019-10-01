import configureMockStore from 'redux-mock-store';
import React from 'react';
import thunk from 'redux-thunk';
import { shallow as toBeModifiedShallow } from 'enzyme';

import '../../testHelper';
import { SettingsHandler } from '../../../app/assets/javascripts/components/settings/settings_handler.jsx';

let expectedAdminUsers;
const spy = sinon.spy();
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
const createDecoratedEnzyme = (injectProps = {}) => {
  function nodeWithAddedProps(node) {
    return React.cloneElement(node, injectProps);
  }
  function shallow(node, { context } = {}) {
    return toBeModifiedShallow(nodeWithAddedProps(node), {
      context: { ...injectProps, ...context }
    });
  }
  return shallow;
};

describe('SettingsHandler', () => {
  it('passes adminUsers to AdminUsersList', () => {
    expectedAdminUsers = [{ id: 1, username: 'testUser', real_name: 'real name', permissions: 3 }];
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

    const fetchAdminUsers = sinon.stub().returns(expectedAdminUsers);
    // fetchAdminUsers.returns(expectedAdminUsers);

    const decoratedShallow = createDecoratedEnzyme({ store });
    const wrapper = decoratedShallow(
      <SettingsHandler adminUsers={fetchAdminUsers()} fetchAdminUsers={fetchAdminUsers} fetchSpecialUsers={spy}/>
    );

    const container = wrapper;

    expect(
      container.find('AdminUserList').first().props().adminUsers
    ).toEqual(expectedAdminUsers);
  });
});
