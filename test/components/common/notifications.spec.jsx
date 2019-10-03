import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import { Notifications } from '../../../app/assets/javascripts/components/common/notifications.jsx';


describe('Notifications', () => {
  it('renders', () => {
    const rendered = shallow(<Notifications notifications={[]} />);
    expect(rendered).toExist;
  });

  it('shows nothing when initially renderd', () => {
    const rendered = shallow(<Notifications notifications={[]} />);

    const rows = rendered.find('.notice');
    expect(rows.length).toEqual(0);
  });

  it('shows an error when the state reflects that', () => {
    const notifications = [
      { type: 'error', message: 'error message' }
    ];
    const rendered = shallow(<Notifications notifications={notifications} />);
    const rows = rendered.find('.notice');
    expect(rows.length).toEqual(1);
  });
});
