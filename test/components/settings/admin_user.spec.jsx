import '../../testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import AdminUser from '../../../app/assets/javascripts/components/settings/admin_user.jsx';

import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('AdminUser', () => {
  it('renders user info', () => {
    const expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };
    const store = mockStore({
      settings: {
        adminUsers: [expectedUser],
        revokingAdmin: {
          status: false,
          username: null,
        }
      },
      notifications: [],
    });

    const wrapper = shallow(<Provider store={store} >
      <AdminUser />
    </Provider>);

    const cells = wrapper.find('td');

    const expectedCellValues = [
      expectedUser.username,
      expectedUser.real_name,
      expectedUser.permissions === 3 ?
        'Super Admin' :
        'Admin',
    ];

    cells.forEach((cell, idx) => {
      expect(
        cell.find('p').first().text()
      ).to.equal(expectedCellValues[idx]);
    });
  });
});
