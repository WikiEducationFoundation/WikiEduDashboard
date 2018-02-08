import '../../testHelper';
import React from 'react';
import { mount } from 'enzyme';
import AdminUserContainer from '../../../app/assets/javascripts/components/settings/containers/admin_user_container.jsx';
import AdminUser from '../../../app/assets/javascripts/components/settings/views/admin_user.jsx';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import sinon from 'sinon';
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('AdminUser', () => {
  describe('revoke button not active', () => {
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
            <AdminUserContainer user={expectedUser} key={1} />
          </tbody>
        </table>
      </Provider>);
    });

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
      });
    });

    it('renders the revoking button', () => {
      const button = wrapper.find('td p button').first();
      expect(button.text())
        .to.equal(I18n.t('settings.admin_users.remove.revoke_button'));
      expect(button.hasClass('dark')).to.equal(true);
    });
  }); // not revoking

  describe('revoke button active', () => {
    it('renders the revoking button', () => {
      const expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };
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

      const wrapper = mount(<Provider store={store} >
        <table>
          <tbody>
            <AdminUserContainer user={expectedUser} key={1} />
          </tbody>
        </table>
      </Provider>);

      const button = wrapper.find('td p button').first();
      expect(button.text())
        .to.equal(I18n.t('settings.admin_users.remove.revoking_button_working'));
      expect(button.hasClass('border')).to.equal(true);
    });
  });

  describe('handleRevoke', () => {
    it('calls handleRevoke on button click', () => {
      const expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };
      const revokingAdmin = {
        status: true,
        username: expectedUser.username,
      };
      const handleRevokeSpy = sinon.spy(AdminUser.prototype, 'handleRevoke');
      const wrapper = mount(
        <table>
          <tbody>
            <AdminUser user={expectedUser} key={1} revokingAdmin={revokingAdmin} />
          </tbody>
        </table>
      );
      const button = wrapper.find('tr td p button');

      button.simulate('click');
      expect(handleRevokeSpy.calledOnce).to.equal(true);
    });
  });
});
