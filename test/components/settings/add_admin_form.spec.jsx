import React from 'react';
import configureMockStore from 'redux-mock-store';
//  importing shallow as toBeModifiedShallow as shallow(<Provider><Component /><Provider> causes issues)
import { shallow as toBeModifiedShallow } from 'enzyme';
import thunk from 'redux-thunk';

import '../../testHelper';
import AddAdminForm from '../../../app/assets/javascripts/components/settings/views/add_admin_form.jsx';

//  new shallow defined for accepting props
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
  //  decorated shallow allows store to be passed , current react-redux v6 bug
  const decoratedShallow = createDecoratedEnzyme({ store });
  beforeEach(() => {
    expectedUser = { id: 1, username: 'testUser', real_name: 'real name', permissions: 3 };

    wrapper = decoratedShallow(
      <AddAdminForm />
    );
  });

  describe('not confirming', () => {
    it('renders form', () => {
      expect(
        wrapper.find('#new_admin_name').first().prop('label')
      ).toEqual(I18n.t('settings.admin_users.new.form_label'));
    });

    it('renders submit button', () => {
      expect(
        wrapper.find('button').first().text()
      ).toEqual(I18n.t('application.submit'));
    });

    it('input onChange calls handleUsernameChange ', () => {
      const input = wrapper.find('#new_admin_name').first();
      const event = ['_', expectedUser.username];
      input.simulate('change', ...event);
      expect(
        wrapper.state().username
      ).toEqual(expectedUser.username);
    });

    it('updates text field on state change', () => {
      wrapper.setState({ username: expectedUser.username });
      expect(
        wrapper.find('#new_admin_name').first().prop('value')
      ).toEqual(expectedUser.username);
    });


    it('form submit calls handleSubmit', () => {
      const submitSpy = sinon.spy();
      const mockEvent = { preventDefault: submitSpy };
      const form = wrapper.find('form');
      form.simulate('submit', mockEvent);
      expect(
        submitSpy.calledOnce
      ).toEqual(true);
    });
  }); // not confirming

  describe('confirming', () => {
    beforeEach(() => {
      wrapper.setState({ confirming: true, username: 'someuser' });
    });

    it('renders a non editable form', () => {
      expect(
        wrapper.find('#new_admin_name').first().prop('editable')
      ).toEqual(undefined);
    });

    it('renders confirm button', () => {
      expect(
        wrapper.find('button').first().text()
      ).toEqual(I18n.t('settings.admin_users.new.confirm_add_admin'));
    });
  });

  describe('submitting', () => {
    beforeEach(() => {
      wrapper = decoratedShallow(
        <AddAdminForm submittingNewAdmin />
      );
      wrapper.setState({ confirming: true, username: 'someuser' });
    });

    it('renders a spinner', () => {
      expect(
        wrapper.find('.loading__spinner')
      ).toHaveLength(1);
    });
  });
});

