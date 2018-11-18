import React from 'react';
import configureMockStore from 'redux-mock-store';
import { shallow } from 'enzyme';
import thunk from 'redux-thunk';

import '../../testHelper';
import AddAdminForm from '../../../app/assets/javascripts/components/settings/views/add_admin_form.jsx';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
describe('AddAdminForm', () => {
  let expectedUser;
  let wrapper;
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

    wrapper = shallow(
      <AddAdminForm store={store} />
    );
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
      const input = wrapper.find('#new_admin_name').first();
      const event = ['_', expectedUser.username];
      input.simulate('change', ...event);
      expect(
        wrapper.state().username
      ).to.equal(expectedUser.username);
    });

    it('updates text field on state change', () => {
      wrapper.setState({ username: expectedUser.username });
      expect(
        wrapper.find('#new_admin_name').first().prop('value')
      ).to.equal(expectedUser.username);
    });


    it('form submit calls handleSubmit', () => {
      const submitSpy = sinon.spy();
      const mockEvent = { preventDefault: submitSpy };
      const form = wrapper.find('form');
      form.simulate('submit', mockEvent);
      expect(
        submitSpy.calledOnce
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
