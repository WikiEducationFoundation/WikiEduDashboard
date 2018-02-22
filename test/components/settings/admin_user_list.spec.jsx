import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import AdminUserList from '../../../app/assets/javascripts/components/settings/admin_users_list.jsx';

describe('AdminUserList', () => {
  it('renders a List component with correct elements', () => {
    const expectedAdminUsers = [{ id: 1, username: 'testUser', real_name: 'real name', permissions: 3 }];
    const wrapper = shallow(<AdminUserList adminUsers={expectedAdminUsers} />);

    const renderedUsers = wrapper
      .find('List')
      .first()
      .props()
      .elements.map((elem) => {
      return elem.props.user;
    });

    expect(renderedUsers).to.eql(expectedAdminUsers);
  });

  it('renders the correct empty message', () => {
    const expectedAdminUsers = [];
    const wrapper = shallow(<AdminUserList adminUsers={expectedAdminUsers} />);
    const list = wrapper.find('List').first();
    const renderedUsers = list
      .props()
      .elements.map((elem) => {
        return elem.props.user;
      });

    expect(renderedUsers).to.eql([]);
    expect(list.props().none_message).to.equal('no admin users');
  });
});
