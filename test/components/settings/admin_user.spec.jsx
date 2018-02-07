import '../../testHelper';
import React from 'react';
import { shallow, mount } from 'enzyme';
import AdminUser from '../../../app/assets/javascripts/components/settings/admin_user.jsx';

import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('AdminUser', () => {

  describe('not revoking', () => {
    let expectedUser;
    let wrapper;
    beforeEach(() => {
      expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };
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

      wrapper = mount(<Provider store={store} >
        <table>
          <tbody>
            <AdminUser user={expectedUser} key={1} />
          </tbody> 
        </table>
      </Provider>);
    })

    it('renders user info', () => {
      const cells = wrapper.find('td');

      const expectedCellValues = [
        expectedUser.username,
        expectedUser.real_name,
        expectedUser.permissions === 3 ?
          'Super Admin' :
          'Admin',
      ];

      expectedCellValues.forEach((expectedValue, idx) => {
        expect(
          cells.at(idx).find('p').first().text()
        ).to.equal(expectedValue);
      })
    });

    it('renders the revoking button', () => {
      const button = wrapper.find('td p button').first();
      expect(button.text())
        .to.equal(I18n.t('settings.admin_users.remove.revoke_button'))
      expect(button.hasClass('dark')).to.equal(true)
    })
  }) // not revoking

  describe('revoking', () => {
    let expectedUser;
    let wrapper;
    beforeEach(() => {
      expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };
      const store = mockStore({
        settings: {
          adminUsers: [expectedUser],
          revokingAdmin: {
            status: true,
            username: expectedUser.username,
          }
        },
        notifications: [],
      });

      wrapper = mount(<Provider store={store} >
        <table>
          <tbody>
            <AdminUser user={expectedUser} key={1} />
          </tbody> 
        </table>
      </Provider>);
    })

    it('renders the revoking button', () => {
      const button = wrapper.find('td p button').first();
      expect(button.text())
        .to.equal(I18n.t('settings.admin_users.remove.revoking_button_working'))
      expect(button.hasClass('border')).to.equal(true)
    })
  })

});
