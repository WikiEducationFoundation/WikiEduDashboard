import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router';

import CourseAlerts from '../../../app/assets/javascripts/components/course/course_alerts.jsx';
import '../../testHelper';

describe('CourseAlerts', () => {
  const props = {
    userRoles: {},
    course: {},
    courseAlerts: {},
    courseLinkParams: '',
    usersLoaded: true,
    studentCount: 100,
    weeks: [],
    updateCourse: sinon.stub(),
    persistCourse: sinon.stub(),
    dismissNotification: sinon.stub()
  };

  it('will show an alert for requested accounts', () => {
    const requestedAccountProps = {
      ...props,
      userRoles: {
        isAdvancedRole: true
      },
      course: { requestedAccounts: 1 }
    };
    const component = mount(
      <MemoryRouter>
        <CourseAlerts {...requestedAccountProps} />
      </MemoryRouter>
    );
    const notifications = component.find('.notification');

    expect(notifications.length).toBeGreaterThan(0);
    expect(notifications.at(1).text()).toEqual('1 requested account pending.View');
  });
});
