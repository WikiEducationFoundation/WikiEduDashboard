import '../../testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import AddAdminForm from '../../../app/assets/javascripts/components/settings/views/add_admin_form.jsx';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
describe('AddAdminForm', () => {
  let expectedUser;
  let wrapper;
  let handleSubmitSpy;
  let handleUsernameChangeSpy;
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
  beforeEach(() => {
    expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };

    handleSubmitSpy = sinon.spy(AddAdminForm.prototype, 'handleSubmit');

    handleUsernameChangeSpy = sinon.spy(AddAdminForm.prototype, 'handleUsernameChange');

    wrapper = shallow(
      <AddAdminForm store={store} />
    );
  });

  afterEach(() => {
    AddAdminForm.prototype.handleSubmit.restore();
    AddAdminForm.prototype.handleUsernameChange.restore();
  });
  describe('not confirming', () => {
    it('renders form', () => {
      expect(
        wrapper.find('#new_admin_name').first().prop('label')
      ).to.eq(I18n.t('settings.admin_users.new.form_label'));
    });

    it('renders submit button', () => {
      expect(
        wrapper.find('button').first().text()
      ).to.eq(I18n.t('application.submit'));
    });

    it('input onChange calls handleUsernameChange ', () => {
      // TODO!
      const input = wrapper.find('#new_admin_name').first();
      const event = { target: { name: 'username', value: expectedUser.username } };
      input.simulate('change', event);
      expect(
        handleUsernameChangeSpy.calledOnce
      ).to.equal(true);
    });

    it('updates text field on state change', () => {
      wrapper.setState({ username: expectedUser.username });
      expect(
        wrapper.find('#new_admin_name').first().prop('value')
      ).to.equal(expectedUser.username);
    });

    it('form submit calls handleSubmit', () => {
      const event = {
        preventDefault: () => {}
      };
      const form = wrapper.find('form');
      form.simulate('submit', event);
      expect(
        handleSubmitSpy.calledOnce
      ).to.equal(true);
    });
  }); // not confirming

  describe('confirming', () => {
    beforeEach(() => {
      wrapper.setState({ confirming: true, username: 'someuser' });
    });

    it('renders a non editable form', () => {
      expect(
        wrapper.find('#new_admin_name').first().prop('editable')
      ).to.eq(undefined);
    });

    it('renders confirm button', () => {
      expect(
        wrapper.find('button').first().text()
      ).to.eq(I18n.t('settings.admin_users.new.confirm_add_admin'));
    });
  });

  describe('submitting', () => {
    beforeEach(() => {
      wrapper = shallow(
        <AddAdminForm submittingNewAdmin store={store} />
      );
      wrapper.setState({ confirming: true, username: 'someuser' });
    });

    it('renders a spinner', () => {
      expect(
        wrapper.find('.loading__spinner')
      ).to.have.length(1);
    });
  });
});
