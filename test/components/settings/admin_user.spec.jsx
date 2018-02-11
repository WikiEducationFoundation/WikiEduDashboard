import { Provider } from 'react-redux';
import React from 'react';
import configureMockStore from 'redux-mock-store';
import { mount, shallow } from 'enzyme';
import sinon from 'sinon';
import thunk from 'redux-thunk';

import '../../testHelper';
import AdminUser from '../../../app/assets/javascripts/components/settings/views/admin_user.jsx';
import AdminUserContainer from '../../../app/assets/javascripts/components/settings/containers/admin_user_container.jsx';

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
      expect(button.hasClass('danger')).to.equal(true);
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

  describe('handleClick', () => {
    let handleRevokeSpy;
    const expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };

    it('calls handleClick on button click', () => {
      const revokingAdmin = {
        status: true,
        username: expectedUser.username,
      };
      handleRevokeSpy = sinon.spy(AdminUser.prototype, 'handleClick');
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
      AdminUser.prototype.handleClick.restore();
    });

    it('renders confirmation state', () => {
      const revokingAdmin = {
        status: false,
        username: null,
      };
      const wrapper = shallow(
        <AdminUser user={expectedUser} key={1} revokingAdmin={revokingAdmin} />
      );
      wrapper.setState({ confirming: true });
      const button = wrapper.find('tr td p button');
      expect(button.text())
        .to.equal(I18n.t('settings.admin_users.remove.revoke_button_confirm', { username: expectedUser.username })
      );
      expect(button.hasClass('danger')).to.equal(true);
    });
  });
});
