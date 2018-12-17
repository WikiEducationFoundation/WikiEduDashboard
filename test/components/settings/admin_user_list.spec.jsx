import React from 'react';
import { Provider } from 'react-redux';
import { render } from 'enzyme';

import '../../testHelper';
import AdminUserList from '../../../app/assets/javascripts/components/settings/admin_users_list.jsx';

describe('AdminUserList', () => {
  it('renders a List component with correct elements', () => {
    const expectedAdminUsers = [{ id: 1, username: 'testUser', real_name: 'real name', permissions: 3 }];
    const renderedList = render(
      <Provider store={reduxStore}>
        <AdminUserList adminUsers={expectedAdminUsers} />
      </Provider>
    );

    expect(renderedList.find('td.user__username').text()).to.eq('testUser');
  });
});
